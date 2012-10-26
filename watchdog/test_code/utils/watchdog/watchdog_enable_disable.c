#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/watchdog.h>
#include <errno.h>
#include <unistd.h>

#include <stdlib.h> /* for system() */

int main(int argc, const char *argv[])
{

       int return_value;
   //    int timeout_value = 5;
       int status_value = 0;

 //      struct watchdog_info wd_test;

       if (argc < 2) {
               printf("[APP]Please specify <devfs interface> for watchdog!\n");
               printf("[APP]E.g. %s /dev/watchdog\n", argv[0]);
               exit(0);
       }

       int fd = open(argv[2], O_WRONLY);

       if (fd == -1) {
               perror("[APP]Watchdog device interface is not available!\n");
               return 1;
       }

       return_value = ioctl(fd, WDIOC_GETSTATUS, &status_value);

        if (!return_value) {
                printf("[APP]Watchdog status is %d\n", status_value);
        } else {
                printf("[APP]ioctl WDIOC_GETSTATUS failed\n");
                return 1;
        }

	return_value = ioctl(fd, WDIOS_ENABLECARD, &status_value);

        if (!return_value) {
                printf("[APP]Turn on the watchdog timer, status_value:%d\n", status_value);
        } else {
                printf("[APP]ioctl WDIOS_ENABLECARD failed\n");
                return 1;
        }

		if (*argv[1] == '0')
			if ( close(fd) == 0 )
				printf ("[APP]FD closed\n");
	        else
				printf ("[APP]closing watchodf fd error:\n");
		else {
			int pid=getpid();
			char kill[11];
			sprintf(kill, "kill %d", pid);
			system(kill);
		}

        return return_value;

}
