/*
 * HS-UART TEST PROGRAM
 *
 * Driver location: linux/drivers/serial/omap-serial.c
 * This application is meant for testing the UART
 * driver on OMAP Platform.
 *
 * Copyright (C) 2008-2009 Texas Instruments, Inc.
 * Govindraj R <govindraj.raja@ti.com>
 *
 * This package is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 * History:
 */


#include "common.h"

int main(int argc, char **argv)
{
	int i = 0, rd = 0;
	fd_set readFds;
	int retval;
	struct timeval respTime;
	unsigned char input_buf[bufsize], output_buf[bufsize];
	int size = 0;
	int chk_flag, error = 0;

	char md5_sum1[33];
	char cmd_buf [20];

	/* to handle ctrl +c */
	if (signal(SIGINT, signalHandler) == SIG_ERR) {
		printf("ERROR : Failed to register signal handler\n");
		exit(1);
	}

	if (argc != 5) {
		display_intro();
		exit(1);
	}

	chk_flag = sscanf(argv[3], "%li", &ut.baudrate);
	if (chk_flag != 1)
		error = 1;
	chk_flag = sscanf(argv[4], "%i", &ut.flow_cntrl);
	if (chk_flag != 1)
		error = 1;

	if (ut.flow_cntrl < 0 || ut.flow_cntrl > 2)
		error = 1;
	if (error) {
		printf("\n [%s] or [%s] : Invalid command line argument \n",
							argv[3], argv[4]);
		display_intro();
		exit(1);
	}

	ut.fd = open(UART_DEV_NAME, O_RDWR | O_NOCTTY | O_NDELAY | O_NONBLOCK);

	if (ut.fd == -1) {
		printf("\n [%s]: Failure in opening the port\n", UART_DEV_NAME);
		exit(1);
	} else {
		fcntl(ut.fd, F_SETFL, 0);
	}
	printf("\n Existing port baudrate= %d", getbaud(ut.fd));
	/* save current port settings */
	tcgetattr(ut.fd, &oldtio);
	initport(ut.fd, ut.baudrate, ut.flow_cntrl);
	printf("\n Configured port for baudrate= %d", getbaud(ut.fd));

	sscanf(argv[1], "%c", &tx_rx);

	switch (tx_rx) {

	case 'r':
	/* open(const char *pathname, int flags, mode_t mode); */
		fd2 = open(argv[2], O_WRONLY | O_CREAT , S_IRWXU | S_IRWXO);
		if (fd2 == -1) {
			printf("\n [%s]: Failure in opening the file.\n",
								argv[2]);
			close(ut.fd);
			exit(1);
		}
		read_flag = 0;
		while (1) {
			FD_ZERO(&readFds);
			FD_SET(ut.fd, &readFds);
			respTime.tv_sec = 10;
			respTime.tv_usec = 0;

			/* Sleep for command timeout
			 * and expect the response to be ready. */
			retval =
				select(FD_SETSIZE, &readFds,
						NULL, NULL, &respTime);

			if (retval == ERROR)
				printf("\n select: error :: %d\n", retval);

			/* Read data, abort if read fails. */
			if (FD_ISSET(ut.fd, &readFds) != 0)  {
			/*	fcntl(ut.fd, F_SETFL, FNDELAY);	*/
			/*	printf("\n Entering readport \n"); */
				if (read_flag == 0) {
					gettimeofday(&ut.start_time, NULL);
					read_flag = 1;
				}
				rd = readport(&ut.fd, output_buf);
				if (ERROR == rd) {
					printf("Read Port failed\n");
					close_port();
				}
			}
			if (read_flag == 0) {
				if (unlink(argv[2]) == -1)
					printf("\n Failed to delete the \
						file %s \n", argv[2]);
				printf("\n Waited for 10 seconds no data was \
						available to read exiting \n");
				close_port();
			}
			if (rd == 0)
				break;
			size += rd;
			i = write(fd2, &output_buf, rd);
			memset(output_buf, 0, bufsize);
			/* printf("\nport returned %d bytes Written %d \
				bytes to output file",rd,i);
			 */
		}
		gettimeofday(&ut.end_time, NULL);
		printf("\n Read %d bytes from port \n", size);

		sprintf(cmd_buf, "md5sum %s ", argv[2]);
		md5_fd = popen(cmd_buf, "r");
		if (!ferror(md5_fd)) {
			/* md5sum returns 32 bit checksum value */
			fgets(md5_sum1, 32, md5_fd);
			/* Append the read checksum value with null string */
			md5_sum1[32] = '\0';
		} else {
			printf("\n Check sum generation for %s failed \n",
								argv[2]);
			break;
		}
		printf("\n CheckSum generated for [%s] = %s \n",
						argv[2], md5_sum1);

		FD_CLR(ut.fd, &readFds);
		break;

	case 's':
		fd1 = open(argv[2], O_RDONLY);
		if (fd1 == -1) {
			printf("\n cannot open %s \n", argv[2]);
			close(ut.fd);
			exit(1);
		}
		gettimeofday(&ut.start_time, NULL);
		while (1) {
			rd = read(fd1, &input_buf, bufsize);
			if (rd == 0)
			break;
			size += rd;
			/* printf("\n Read from input file %d bytes \n",rd); */
			fcntl(ut.fd, F_SETFL, 0);
			if (!writeport(&ut.fd, input_buf, rd)) {
				printf("\n Writing to port failed\n");
				close_port();
			}
			if (ERROR == tcdrain(ut.fd))
				printf("\n tcdrain failure \n");
			memset(input_buf, 0, bufsize);
		}
		gettimeofday(&ut.end_time, NULL);
		printf("\n Written %d bytes from port \n", size);
		/* Wait for 3 seconds for Transmition to complete before
		 * sending the Break sequence */
		sleep(3);
		/* for(i=0;i<2;i++) */
		if (tcsendbreak(ut.fd, 5) < 0)
			printf("\n Sending break sequence fialed use \
				 ctrl + c to terminate read process\n");

		sprintf(cmd_buf, "md5sum %s ", argv[2]);
		md5_fd = popen(cmd_buf, "r");
		if (!ferror(md5_fd)) {
			/* md5sum returns 32 bit checksum value */
			fgets(md5_sum1, 32, md5_fd);
			/* Append the read checksum value
			 * with null string */
			md5_sum1[32] = '\0';
		} else {
			printf("\n Check sum generation for %s \
					failed \n",argv[2]);
			break;
		}
		printf("\n CheckSum generated for [%s] = %s \n",
						argv[2], md5_sum1);
	}

	timersub(&ut.end_time, &ut.start_time, &ut.diff_time);
	if (tx_rx == 'r')
		 ut.diff_time.tv_sec -= 3;
	printf("\n Time taken %08ld sec, %08ld usec\n\n ",
				ut.diff_time.tv_sec, ut.diff_time.tv_usec);
	pclose(md5_fd);
	/* restore the old port settings. */
	close_port();
	return 0;
}
