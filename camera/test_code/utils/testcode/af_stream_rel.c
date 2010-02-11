/* =========================================================================
 *             Texas Instruments OMAP(TM) Platform Software
 *  (c) Copyright Texas Instruments, Incorporated.  All Rights Reserved.
 *
 *  Use of this software is controlled by the terms and conditions found
 *  in the license agreement under which this software has been supplied.
 * ========================================================================= */

#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <linux/videodev2.h>
#include <errno.h>
#include <mach/isp_user.h>
#include "kbget.h"
#include <string.h>

#define VIDEO_DEVICE1 "/dev/video1"
#define VIDEO_DEVICE2 "/dev/video2"

#define DEFAULT_PIXEL_FMT "YUYV"
#define DEFAULT_VIDEO_SIZE "VGA"

#define MODE_MANUAL		1
#define MODE_AUTO		2

#define DSS_STREAM_START_FRAME	3

int cfd, vfd;

static void usage(void)
{
	printf("af_stream_rel [dev] [vid] [framerate] [test]\n");
	printf("\tSteaming capture of 1000 frames using video driver for"
							" rendering\n");
	printf("\t[dev] Camera device to be open\n\t 1:Micron sensor "
					"2:OV sensor  3:IMX046 sensor\n");
	printf("\t[vid] is the video pipeline to be used. Valid vid is"
							" 1(default) or 2\n");
	printf("\t[framerate] is the framerate to be used, if no value"
					"is given 30 fps is default\n");
	printf("\t[test] is the test mode:\n\t"
					"AUTO   - Auto test\n\t"
					"MANUAL - Manual test (default)\n");
}

static void display_keys(void)
{
	printf("\nControl Keys:\n");
	printf("  1 - VIDIOC_PRIVATE_ISP_AF_REQ ioctl\n");
	printf("  2 - Change lens position relative -1\n");
	printf("  3 - Change lens position relative +1\n");
	printf("  4 - Change lens position relative -5\n");
	printf("  5 - Change lens position relative +5\n");
	printf("  q - Quit\n\n");
}

int auto_test(int cfd, int count)
{
	static int dir = -1;
	struct v4l2_control control;

	if (count % 50 == 0) {
		memset(&control, 0, sizeof(control));
		control.id = V4L2_CID_FOCUS_RELATIVE;
		control.value = 250 * dir;
		printf("Focus: %s\n", (dir == 1) ? "INFINTE" : "MACRO");
		if (ioctl(cfd, VIDIOC_S_CTRL, &control) == -1)
			perror("Error V4L2_CID_FOCUS_RELATIVE: ");
		dir *= -1;
	}

	return 0;
}

int main(int argc, char *argv[])
{
	struct {
		void *start;
		size_t length;
	} *vbuffers;

	struct v4l2_capability capability;
	struct v4l2_format cformat, vformat;
	struct v4l2_requestbuffers creqbuf, vreqbuf;
	struct v4l2_buffer cfilledbuffer, vfilledbuffer;
	struct v4l2_control control;
	int vid = 1, set_video_img = 0, i, ret;

	/*************************************************************/
	unsigned int buff_size = 0;
	struct af_configuration af_config_user;
	struct isp_af_data af_data_user;
	__u16 *buff_preview = NULL;
	__u8 *stats_buff = NULL;
	unsigned int buff_prev_size = 0;
	int k;
	int input;
	__u16 wposn = 1;
	int frame_number;
	int index = 1;
	FILE *fp_out;
	int framerate = 30;
	int device = 1, mode = MODE_MANUAL;

	/* V4L2 Video Event handling */
	struct v4l2_event_subscription cam_sub;
	struct v4l2_event cam_ev;
	fd_set excfds;

	af_config_user.alaw_enable = H3A_AF_ALAW_ENABLE;	/* Enable Alaw */
	af_config_user.hmf_config.enable = H3A_AF_HMF_DISABLE;
	af_config_user.iir_config.hz_start_pos = 0;
	af_config_user.paxel_config.height = 16;
	af_config_user.paxel_config.width = 16;
	af_config_user.paxel_config.line_incr = 0;
	af_config_user.paxel_config.vt_start = 0;
	af_config_user.paxel_config.hz_start = 2;
	af_config_user.paxel_config.hz_cnt = 8;
	af_config_user.paxel_config.vt_cnt = 8;
	af_config_user.af_config = H3A_AF_CFG_ENABLE;
	af_config_user.hmf_config.threshold = 0;
	/* Set Accumulator mode */
	af_config_user.mode = ACCUMULATOR_SUMMED;

	for (index = 0; index < 11; index++) {
		af_config_user.iir_config.coeff_set0[index] = 12;
		af_config_user.iir_config.coeff_set1[index] = 12;
	}
	/* ********************************************************* */
	fp_out = fopen("af_mid.st", "wb");
	if (fp_out == NULL) {
		printf("ERROR opening output file!\n");
		return -EACCES;
	}
	/* ********************************************************* */

	index = 1;
	if (argc < 2) {
		printf("ERROR: Missing parameters!\n");
		usage();
		return 0;
	}
	if ((argc > 1) && (!strcmp(argv[1], "?"))) {
		usage();
		return 0;
	}

	if (argc > index) {
		device = atoi(argv[index]);
		index++;
	}

	if (argc > index) {
		vid = atoi(argv[index]);
		if ((vid != 1) && (vid != 2)) {
			printf("vid has to be 1 or 2! vid=%d, argv[1]=%s\n",
								vid, argv[1]);
			usage();
			return 0;
		}
	}
	index++;

	if (argc > index) {
		framerate = atoi(argv[index]);
		printf("Framerate = %d\n", framerate);
		index++;
	} else
		printf("Using framerate = 30, default value\n");

	if (argc > index) {
		if (strcmp(argv[index], "AUTO") == 0)
			mode = MODE_AUTO;
		index++;
	}

	if (mode == MODE_AUTO)
		printf("Mode: Auto test\n");
	else
		printf("Mode: Manual test\n");


	cfd = open_cam_device(O_RDWR, device);
	if (cfd <= 0) {
		printf("Could not open the cam device\n");
		return -1;
	}

	vfd = open((vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2, O_RDWR);
	if (vfd <= 0) {
		printf("Could not open %s\n",
				(vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2);
		return -1;
	} else {
		printf("openned %s for rendering\n",
				(vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2);
	}

	if (ioctl(vfd, VIDIOC_QUERYCAP, &capability) == -1) {
		perror("video VIDIOC_QUERYCAP");
		return -1;
	}
	if (capability.capabilities & V4L2_CAP_STREAMING)
		printf("The video driver is capable of Streaming!\n");
	else {
		printf("The video driver is not capable of Streaming!\n");
		return -1;
	}

	if (ioctl(cfd, VIDIOC_QUERYCAP, &capability) < 0) {
		perror("VIDIOC_QUERYCAP");
		return -1;
	}
	if (capability.capabilities & V4L2_CAP_STREAMING)
		printf("The camera driver is capable of Streaming!\n");
	else {
		printf("The camera driver is not capable of Streaming!\n");
		return -1;
	}

	memset(&control, 0, sizeof(control));


	ret = setFramerate(cfd, framerate);
	if (ret < 0) {
		printf("ERROR: VIDIOC_S_PARM ioctl cam\n");
		return -1;
	}

	ret = cam_ioctl(cfd, DEFAULT_PIXEL_FMT, DEFAULT_VIDEO_SIZE);
	if (ret < 0) {
		printf("ERROR: VIDIOC_S_FMT ioctl cam\n");
		return -1;
	}

	cformat.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(cfd, VIDIOC_G_FMT, &cformat);
	if (ret < 0) {
		perror("cam VIDIOC_G_FMT");
		return -1;
	}
	printf("Camera Image width = %d, Image height = %d, size = %d\n",
						cformat.fmt.pix.width,
						cformat.fmt.pix.height,
						cformat.fmt.pix.sizeimage);

	vformat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(vfd, VIDIOC_G_FMT, &vformat);
	if (ret < 0) {
		perror("video VIDIOC_G_FMT");
		return -1;
	}
	printf("Video Image width = %d, Image height = %d, size = %d\n",
						vformat.fmt.pix.width,
						vformat.fmt.pix.height,
						vformat.fmt.pix.sizeimage);

	if ((cformat.fmt.pix.width != vformat.fmt.pix.width) ||
						(cformat.fmt.pix.height !=
						vformat.fmt.pix.height)) {
		printf("image sizes don't match!\n");
		set_video_img = 1;
	}
	if (cformat.fmt.pix.pixelformat != vformat.fmt.pix.pixelformat) {
		printf("pixel formats don't match!\n");
		set_video_img = 1;
	}

	if (set_video_img) {
		printf("set video image the same as camera image ...\n");
		vformat.fmt.pix.width = cformat.fmt.pix.width;
		vformat.fmt.pix.height = cformat.fmt.pix.height;
		vformat.fmt.pix.sizeimage = cformat.fmt.pix.sizeimage;
		vformat.fmt.pix.pixelformat = cformat.fmt.pix.pixelformat;
		ret = ioctl(vfd, VIDIOC_S_FMT, &vformat);
		if (ret < 0) {
			perror("video VIDIOC_S_FMT");
			return -1;
		}
		if ((cformat.fmt.pix.width != vformat.fmt.pix.width) ||
						(cformat.fmt.pix.height !=
						vformat.fmt.pix.height) ||
						(cformat.fmt.pix.pixelformat !=
						vformat.fmt.pix.pixelformat)) {
			printf("can't make camera and video image"
							" compatible!\n");
			return 0;
		}
	}

	vreqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	vreqbuf.memory = V4L2_MEMORY_MMAP;
	vreqbuf.count = 4;
	if (ioctl(vfd, VIDIOC_REQBUFS, &vreqbuf) == -1) {
		perror("video VIDEO_REQBUFS");
		return;
	}
	printf("Video Driver allocated %d buffers when 4 are requested\n",
								vreqbuf.count);

	vbuffers = calloc(vreqbuf.count, sizeof(*vbuffers));
	for (i = 0; i < vreqbuf.count ; ++i) {
		struct v4l2_buffer buffer;
		buffer.type = vreqbuf.type;
		buffer.index = i;
		if (ioctl(vfd, VIDIOC_QUERYBUF, &buffer) == -1) {
			perror("video VIDIOC_QUERYBUF");
			return;
		}
		vbuffers[i].length = buffer.length;
		vbuffers[i].start = mmap(NULL, buffer.length, PROT_READ |
						PROT_WRITE, MAP_SHARED,
						vfd, buffer.m.offset);
		if (vbuffers[i].start == MAP_FAILED) {
			perror("video mmap");
			return;
		}
		printf("Video Buffers[%d].start = %x  length = %d\n", i,
					vbuffers[i].start, vbuffers[i].length);
	}

	creqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	creqbuf.memory = V4L2_MEMORY_USERPTR;
	creqbuf.count = 4;
	printf("Requesting %d buffers of type V4L2_MEMORY_USERPTR\n",
								creqbuf.count);
	if (ioctl(cfd, VIDIOC_REQBUFS, &creqbuf) < 0) {
		perror("cam VIDEO_REQBUFS");
		return -1;
	}
	printf("Camera Driver allowed %d buffers\n", creqbuf.count);

	for (i = 0; i < creqbuf.count; ++i) {
		struct v4l2_buffer buffer;
		buffer.type = creqbuf.type;
		buffer.memory = creqbuf.memory;
		buffer.index = i;
		if (ioctl(cfd, VIDIOC_QUERYBUF, &buffer) < 0) {
			perror("cam VIDIOC_QUERYBUF");
			return -1;
		}

		buffer.flags = 0;
		buffer.m.userptr = (unsigned long) vbuffers[i].start;
		buffer.length = vbuffers[i].length;

		if (ioctl(cfd, VIDIOC_QBUF, &buffer) < 0) {
			perror("cam VIDIOC_QBUF");
			return -1;
		}
	}

	/* Set AF params */
	ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_CFG, &af_config_user);
	if (ret < 0) {
		printf("Error: %d, ", ret);
		perror("ISP_AF_CFG 1");
		return ret;
	}

	/* Subscribe to internal SCM AF_DONE event */
	cam_sub.type = V4L2_EVENT_OMAP3ISP_AF;

	ret = ioctl(cfd, VIDIOC_SUBSCRIBE_EVENT, &cam_sub);
	if (ret < 0)
		perror("subscribe()");

	/* Init file descriptor list to check with select call */
	FD_ZERO(&excfds);
	FD_SET(cfd, &excfds);

	/* turn on streaming on camera driver */
	if (ioctl(cfd, VIDIOC_STREAMON, &creqbuf.type) < 0) {
		perror("cam VIDIOC_STREAMON");
		return -1;
	}

	/* capture 1000 frames */
	cfilledbuffer.type = creqbuf.type;
	vfilledbuffer.type = vreqbuf.type;
	i = 0;

	buff_size = (af_config_user.paxel_config.hz_cnt + 1) *
			(af_config_user.paxel_config.vt_cnt + 1) *
			AF_PAXEL_SIZE;

	stats_buff = malloc(buff_size);
	af_data_user.af_statistics_buf = stats_buff;

	buff_prev_size = (buff_size / 2);

	printf("Syncup on frame number, before starting streaming\n");
	do {
		ret = pselect(cfd + 1, NULL, NULL, &excfds, NULL, NULL);
		if (ret < 0) {
			perror("cam select()");
			return -1;
		}

		ret = ioctl(cfd, VIDIOC_DQEVENT, &cam_ev);
		if (ret < 0) {
			perror("cam DQEVENT");
			return -1;
		}
	} while (cam_ev.type != V4L2_EVENT_OMAP3ISP_AF);

	/* Syncup on frame number */
	af_data_user.update = 0;
	printf("Getting first parameters \n");
	ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ, &af_data_user);
	if (ret < 0)
		perror("ISP_AF_REQ 1");

	printf("Request Frame No: %d\n", af_data_user.frame_number);
	printf("Current Frame No: %d\n", af_data_user.curr_frame);
	af_data_user.frame_number = af_data_user.curr_frame - 1;

	/* Request stats */
	af_data_user.update = REQUEST_STATISTICS;
	printf("Requesting stats for frame %d\n", af_data_user.frame_number);
	ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ, &af_data_user);
	if (ret < 0) {
		perror("ISP_AF_REQ 2");
		return -1;
	}

	printf("Frame No %d\n", af_data_user.frame_number);
	printf("xs.ts %d:%d\n", af_data_user.xtrastats.ts.tv_sec,
			af_data_user.xtrastats.ts.tv_usec);
	printf("xs.field_count %d\n", af_data_user.xtrastats.field_count);
	printf("xs.lens_position %d\n", af_data_user.xtrastats.lens_position);

	/* Display stats */
	buff_preview = (__u16 *)af_data_user.af_statistics_buf;
	printf("H3A AE/AWB: buffer to display = %d data pointer = %p\n",
		buff_prev_size, af_data_user.af_statistics_buf);
	for (k = 0; k < 1024; k++)
		fprintf(fp_out, "%6x\n", buff_preview[k]);

	if (mode == MODE_MANUAL)
		display_keys();

	while (i < 1000 || mode == MODE_MANUAL) {
		/* De-queue the next avaliable buffer */
		while (ioctl(cfd, VIDIOC_DQBUF, &cfilledbuffer) < 0)
			perror("cam VIDIOC_DQBUF");

		vfilledbuffer.index = cfilledbuffer.index;
		vfilledbuffer.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		vfilledbuffer.memory = V4L2_MEMORY_MMAP;
		vfilledbuffer.m.userptr =
			(unsigned int)(vbuffers[cfilledbuffer.index].start);
		vfilledbuffer.length = cfilledbuffer.length;
		if (ioctl(vfd, VIDIOC_QBUF, &vfilledbuffer) < 0) {
			perror("dss VIDIOC_QBUF");
			return -1;
		}
		i++;

		if (i == DSS_STREAM_START_FRAME) {
			/* Turn on streaming for video */
			if (ioctl(vfd, VIDIOC_STREAMON, &vreqbuf.type)) {
				perror("dss VIDIOC_STREAMON");
				return -1;
			}
		}

		if (i >= DSS_STREAM_START_FRAME) {
			/* De-queue the previous buffer from video driver */
			if (ioctl(vfd, VIDIOC_DQBUF, &vfilledbuffer)) {
				perror("dss VIDIOC_DQBUF");
				return;
			}

			cfilledbuffer.index = vfilledbuffer.index;
			while (ioctl(cfd, VIDIOC_QBUF, &cfilledbuffer) < 0)
				perror("cam VIDIOC_QBUF");
		}


		if (mode == MODE_AUTO) {
			auto_test(cfd, i);

			/* Request stats every second */
			if (!(i % framerate)) {
				do {
					ret = pselect(cfd + 1, NULL, NULL, &excfds,
						      NULL, NULL);
					if (ret < 0) {
						perror("cam select()");
						return -1;
					}

					ret = ioctl(cfd, VIDIOC_DQEVENT, &cam_ev);
					if (ret < 0) {
						perror("cam DQEVENT");
						return -1;
					}
				} while (cam_ev.type != V4L2_EVENT_OMAP3ISP_AF);

				af_data_user.update = 0;
				ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ,
							 &af_data_user);
				if (ret < 0) {
					perror("ISP_AF_REQ 3");
					return ret;
				}

				af_data_user.frame_number =
						af_data_user.curr_frame - 1;
				af_data_user.update = REQUEST_STATISTICS;
				ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ,
							 &af_data_user);
				if (ret < 0)
					perror("ISP_AF_REQ 4");
				printf("Stats success! (frame: %d)\n",
				       af_data_user.curr_frame);
			}
		}

		if (kbhit() && mode == MODE_MANUAL) {
			input = getch();
			if (input == '1') {
				ret = pselect(cfd + 1, NULL, NULL, &excfds,
					      NULL, NULL);
				if (ret < 0) {
					perror("cam select()");
					return -1;
				}

				ret = ioctl(cfd, VIDIOC_DQEVENT, &cam_ev);
				if (ret < 0) {
					perror("cam DQEVENT");
					return -1;
				}

				af_data_user.update = 0;
				ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ,
							 &af_data_user);
				if (ret < 0) {
					perror("ISP_AF_REQ 3");
					return ret;
				}

				af_data_user.frame_number =
						af_data_user.curr_frame - 1;
				af_data_user.update = REQUEST_STATISTICS;
				af_data_user.af_statistics_buf = stats_buff;
				ret = ioctl(cfd, VIDIOC_PRIVATE_ISP_AF_REQ,
							 &af_data_user);
				if (ret < 0) {
					perror("ISP_AF_REQ 4");
				} else {
					printf("Frame No %d\n",
						af_data_user.frame_number);
					printf("xs.ts %d:%d\n", af_data_user.xtrastats.
							ts.tv_sec,
							af_data_user.xtrastats.
							ts.tv_usec);
					printf("xs.field_count %d\n", af_data_user.
							xtrastats.field_count);
					printf("xs.lens_position %d\n",
							af_data_user.xtrastats.
							lens_position);

					buff_preview = (__u16 *)af_data_user.
							af_statistics_buf;
					printf("H3A AE/AWB: buffer to display = %d"
							" data pointer = %p\n",
							buff_prev_size,
							af_data_user.af_statistics_buf);
				}
			} else if (input == '2') {
				control.id = V4L2_CID_FOCUS_RELATIVE;
				control.value = -1;
				if (ioctl(cfd, VIDIOC_S_CTRL, &control) == -1)
					perror("Error V4L2_CID_FOCUS_RELATIVE: ");
				printf("Lens position: -1\n");
			} else if (input == '3') {
				control.id = V4L2_CID_FOCUS_RELATIVE;
				control.value = 1;
				if (ioctl(cfd, VIDIOC_S_CTRL, &control) == -1)
					perror("Error V4L2_CID_FOCUS_RELATIVE: ");
				printf("Lens position: +1\n");
			} else if (input == '4') {
				control.id = V4L2_CID_FOCUS_RELATIVE;
				control.value = -5;
				if (ioctl(cfd, VIDIOC_S_CTRL, &control) == -1)
					perror("Error V4L2_CID_FOCUS_RELATIVE: ");
				printf("Lens position: -5\n");
			} else if (input == '5') {
				control.id = V4L2_CID_FOCUS_RELATIVE;
				control.value = 5;
				if (ioctl(cfd, VIDIOC_S_CTRL, &control) == -1)
					perror("Error V4L2_CID_FOCUS_RELATIVE: ");
				printf("Lens position: +5\n");
			} else if (input == 'q') {
				break;
			}
		}

	/* ******************************* */
	}

	printf("Captured and rendered %d frames!\n", i);

	if (ioctl(cfd, VIDIOC_STREAMOFF, &creqbuf.type) == -1) {
		perror("cam VIDIOC_STREAMOFF");
		return -1;
	}
	if (ioctl(vfd, VIDIOC_STREAMOFF, &vreqbuf.type) == -1) {
		perror("video VIDIOC_STREAMOFF");
		return -1;
	}

	for (i = 0; i < vreqbuf.count; i++) {
		if (vbuffers[i].start)
			munmap(vbuffers[i].start, vbuffers[i].length);
	}

	free(vbuffers);
	free(stats_buff);

	close(cfd);
	close(vfd);
}
