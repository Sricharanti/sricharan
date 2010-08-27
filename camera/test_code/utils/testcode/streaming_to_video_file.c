/* =========================================================================
*             Texas Instruments OMAP(TM) Platform Software
*  (c) Copyright Texas Instruments, Incorporated.  All Rights Reserved.
*
*  Use of this software is controlled by the terms and conditions found
*  in the license agreement under which this software has been supplied.
* ========================================================================== */

#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <linux/videodev2.h>
#include <string.h>
#include <stdlib.h>

#define BRT_TEST		1
#define CONT_TEST		2
#define COLOR_TEST		3

#define VIDEO_DEVICE1		"/dev/video1"
#define VIDEO_DEVICE2		"/dev/video2"

#define DEFAULT_PIXEL_FMT	"YUYV"
#define DEFAULT_VIDEO_SIZE	"QCIF"

#define FRAME_COUNT			300
#define APPLY_COUNT			20

static void usage(void)
{
	printf("streaming_to_video_file [camDevice] [pixelFormat]"
	       " [<sizeW> <sizeH>] [(vid)] [(test)] [framerate] [<file>]\n");
	printf("   To start streaming capture of 1000 frames\n");
	printf("   [camDevice] Camera device to be open\n\t 1:Micron sensor "
					"2:OV sensor\n");
	printf("   [pixelFormat] set the pixelFormat to use. \n\tSupported: "
		"YUYV, UYVY, RGB565, RGB555, RGB565X, RGB555X, SGRBG10,"
		" SRGGB10, SBGGR10, SGBRG10 \n");
	printf("   [sizeW] Set the video width\n");
	printf("   [sizeH] Set the video heigth\n");
	printf("\tOptionally size can be specified using standard name sizes"
							"(VGA,PAL,etc)\n");
	printf("\tIf size is NOT specified QCIF used as default\n");
	printf("   [vid] is the video pipeline to be used. Valid vid "
		"is 1(default) or 2\n");
	printf("   [test] Type of test: \"c\" test contrast, \"b\" test "
		"brightness, \"e\" test color\n");
	printf("   [framerate] is the framerate to be used, if no value"
				" is given \n\t      30 fps is default\n");
	printf("   [file] Optionally 10 captured frames can be saved to "
		"file \"streaming_out.yuv\"\n");
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
	FILE *fOut = NULL;
	int cfd, vfd, test, num_frames = 1000;
	int vid = 1, set_video_img = 0, i, ret;
	struct v4l2_queryctrl qc_brightness, qc_contrast, qc_colorfx;
	struct v4l2_control c_brightness, c_contrast, c_colorfx;
	char *pixelFmt;
	int index = 1;
	int framerate = 30;
	int device = 1;
	int orig_brightness, orig_contrast, orig_color;
	int step_brightness, step_contrast;

	if ((argc > index) && (!strcmp(argv[1], "?"))) {
		usage();
		return 0;
	}

	if (argc > index) {
		device = atoi(argv[index]);
		index++;
	}

	cfd = open_cam_device(O_RDWR, device);
	if (cfd <= 0) {
		printf("Could not open the cam device\n");
		return -1;
	}

	if (argc > index) {
		pixelFmt = argv[index];
		index++;
		if (argc > index) {
			ret = validateSize(argv[index]);
			if (ret == 0) {
				ret = cam_ioctl(cfd, pixelFmt, argv[index]);
				if (ret < 0) {
					printf("pixel format specified, "
							"size standard\n");
					usage();
					return -1;
				}
			} else {
				index++;
				if (argc > (index)) {
					ret = cam_ioctl(cfd, pixelFmt,
						argv[index-1], argv[index]);
					if (ret < 0) {
						printf("pixel format specified,"
							"size 2 args\n");
						usage();
						return -1;
					}
				} else {
					printf("Invalid size\n");
					usage();
					return -1;
				}
			}
			index++;
		} else {
			printf("Setting QCIF as video size, default value\n");
			ret = cam_ioctl(cfd, pixelFmt, DEFAULT_VIDEO_SIZE);
			if (ret < 0)
				return -1;
		}
	} else {
		printf("Setting pixel format and video size with default "
							"values\n");
		ret = cam_ioctl(cfd, DEFAULT_PIXEL_FMT, DEFAULT_VIDEO_SIZE);
		if (ret < 0)
			return -1;
	}

	if (argc > index) {
		vid = atoi(argv[index]);
		if ((vid != 1) && (vid != 2)) {
			printf("vid has to be 1 or 2! vid=%d, argv[%d]=%s\n",
			       vid, index, argv[index]);
			usage();
			return 0;
		}

		index++;
	}

	test = 0;
	if (argc > index) {
		if ((!strcmp(argv[index], "b")))
			test = BRT_TEST;
		else if ((!strcmp(argv[index], "c")))
			test = CONT_TEST;
		else if ((!strcmp(argv[index], "e")))
			test = COLOR_TEST;
		else {
			printf("test has to be b, c or e argv[%d]=%s\n",
			       index, argv[index]);
			usage();
			return 0;
		}

		index++;
	}

	if (argc > index) {
		framerate = atoi(argv[index]);
		index++;
	}

	if (argc > index) {
		if (!strcmp(argv[index], "file")) {
			fOut = fopen("streaming_out.yuv", "w");
			if (fOut == NULL) {
				printf("file open error\n");
				return -1;
			}
			printf("File \"steaming_out.yuv\" is open\n");
			num_frames = 10;
		} else {
			printf("must write \"file\" argv[%d]=%s\n", index ,
								argv[index]);
			usage();
			return 0;
		}
		index++;
	}

	ret = setFramerate(cfd, framerate);
	if (ret < 0) {
		printf("Error setting framerate = %d\n", framerate);
		return -1;
	}

	vfd = open((vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2, O_RDWR);
	if (vfd <= 0) {
		printf("Could not open %s\n",
			(vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2);
		return -1;
	}
	printf("openned %s for rendering\n",
		(vid == 1) ? VIDEO_DEVICE1 : VIDEO_DEVICE2);

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

	cformat.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(cfd, VIDIOC_G_FMT, &cformat);
	if (ret < 0) {
		perror("cam VIDIOC_G_FMT");
		return -1;
	}
	printf("Camera Image width = %d, Image height = %d, size = %d\n",
		cformat.fmt.pix.width, cformat.fmt.pix.height,
		cformat.fmt.pix.sizeimage);

	vformat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(vfd, VIDIOC_G_FMT, &vformat);
	if (ret < 0) {
		perror("video VIDIOC_G_FMT");
		return -1;
	}
	printf("Video Image width = %d, Image height = %d, size = %d\n",
		vformat.fmt.pix.width, vformat.fmt.pix.height,
		vformat.fmt.pix.sizeimage);

	if ((cformat.fmt.pix.width != vformat.fmt.pix.width) ||
		(cformat.fmt.pix.height != vformat.fmt.pix.height)) {
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
		    (cformat.fmt.pix.height != vformat.fmt.pix.height) ||
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
	for (i = 0; i < vreqbuf.count; ++i) {
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
		buffer.m.userptr = (unsigned long)vbuffers[i].start;
		buffer.length = vbuffers[i].length;

		if (ioctl(cfd, VIDIOC_QBUF, &buffer) < 0) {
			perror("cam VIDIOC_QBUF");
			return -1;
		}
	}

	/* turn on streaming on both drivers */
	if (ioctl(cfd, VIDIOC_STREAMON, &creqbuf.type) < 0) {
		perror("cam VIDIOC_STREAMON");
		return -1;
	}

	cfilledbuffer.type = creqbuf.type;
	vfilledbuffer.type = vreqbuf.type;

	memset(&qc_brightness, 0, sizeof(qc_brightness));
	memset(&c_brightness, 0, sizeof(c_brightness));

	qc_brightness.id = V4L2_CID_BRIGHTNESS;
	if (ioctl(cfd, VIDIOC_QUERYCTRL, &qc_brightness) == -1)
		printf("Brightness is not supported!\n");
	else {
		c_brightness.id = V4L2_CID_BRIGHTNESS;
		if (ioctl(cfd, VIDIOC_G_CTRL, &c_brightness) == -1) {
			printf("VIDIOC_G_CTRL failed!\n");
			return 0;
		}
		printf("Brightness is supported, min %d, max %d."
			"\nbrightness level is %d\n",
			qc_brightness.minimum, qc_brightness.maximum, c_brightness.value);
		orig_brightness = c_brightness.value;
		step_brightness =
			(qc_brightness.maximum-qc_brightness.minimum) /
			(FRAME_COUNT / APPLY_COUNT);
		printf("Brightness step for this test: %d\n",
			step_brightness);
	}

	memset(&qc_contrast, 0, sizeof(qc_contrast));
	memset(&c_contrast, 0, sizeof(c_contrast));

	qc_contrast.id = V4L2_CID_CONTRAST;
	if (ioctl(cfd, VIDIOC_QUERYCTRL, &qc_contrast) == -1)
		printf("CONTRAST is not supported!\n");
	else {
		c_contrast.id = V4L2_CID_CONTRAST;
		if (ioctl(cfd, VIDIOC_G_CTRL, &c_contrast) == -1)
			printf("VIDIOC_G_CTRL failed!\n");
		printf("CONTRAST is supported, min %d, max %d.\nContrast "
				"level is %d\n", qc_contrast.minimum,
				qc_contrast.maximum, c_contrast.value);
		orig_contrast = c_contrast.value;
		step_contrast = (qc_contrast.maximum-qc_contrast.minimum) /
			(FRAME_COUNT / APPLY_COUNT);
		printf("Contrast step for this test: %d\n",
			step_contrast);
	}

	memset(&qc_colorfx, 0, sizeof(qc_colorfx));
	memset(&c_colorfx, 0, sizeof(c_colorfx));

	qc_colorfx.id = V4L2_CID_COLORFX;
	if (ioctl(cfd, VIDIOC_QUERYCTRL, &qc_colorfx) == -1)
		printf("COLOR effect is not supported!\n");
	else {
		c_colorfx.id = V4L2_CID_COLORFX;
		if (ioctl(cfd, VIDIOC_G_CTRL, &c_colorfx) == -1)
			printf("VIDIOC_G_CTRL failed!\n");
		printf("Color effect is supported, min %d, max %d."
			"\nCurrent color is level is %d\n",
			qc_colorfx.minimum, qc_colorfx.maximum, c_colorfx.value);
		orig_color = c_colorfx.value;
	}

	if (test == BRT_TEST) {
		c_contrast.id = V4L2_CID_CONTRAST;
		c_contrast.value = qc_contrast.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_contrast) == -1)
			printf("VIDIOC_S_CTRL CONTRAST failed!\n");
		c_colorfx.id = V4L2_CID_COLORFX;
		c_colorfx.value = qc_colorfx.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_colorfx) == -1)
			printf("VIDIOC_S_CTRL COLOR failed!\n");
	} else if (test == CONT_TEST) {
		c_brightness.id = V4L2_CID_BRIGHTNESS;
		c_brightness.value = qc_brightness.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_brightness) == -1)
			printf("VIDIOC_S_CTRL BRIGHTNESS failed!\n");
		c_colorfx.id = V4L2_CID_COLORFX;
		c_colorfx.value = qc_colorfx.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_colorfx) == -1)
			printf("VIDIOC_S_CTRL COLOR failed!\n");
	} else if (test == COLOR_TEST) {
		c_contrast.id = V4L2_CID_CONTRAST;
		c_contrast.value = qc_contrast.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_contrast) == -1)
			printf("VIDIOC_S_CTRL CONTRAST failed!\n");
		c_brightness.id = V4L2_CID_BRIGHTNESS;
		c_brightness.value = qc_brightness.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_brightness) == -1)
			printf("VIDIOC_S_CTRL BRIGHTNESS failed!\n");
	} else {
		c_contrast.id = V4L2_CID_CONTRAST;
		c_contrast.value = qc_contrast.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_contrast) == -1)
			printf("VIDIOC_S_CTRL CONTRAST failed!\n");
		c_brightness.id = V4L2_CID_BRIGHTNESS;
		c_brightness.value = qc_brightness.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_brightness) == -1)
			printf("VIDIOC_S_CTRL BRIGHTNESS failed!\n");
		c_colorfx.id = V4L2_CID_COLORFX;
		c_colorfx.value = qc_colorfx.default_value;
		if (ioctl(cfd, VIDIOC_S_CTRL, &c_colorfx) == -1)
			printf("VIDIOC_S_CTRL COLOR failed!\n");
	}

	i = 0;

	while (i < FRAME_COUNT) {
		int aux = 0;
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

		/* Apply change every APPLY_COUNT frames */
		if (((i % APPLY_COUNT) == 0) && (test != 0)) {
			if (test == CONT_TEST) {
				c_contrast.id = V4L2_CID_CONTRAST;
				c_contrast.value += step_contrast;
				if (c_contrast.value > qc_contrast.maximum)
					c_contrast.value = qc_contrast.minimum;
				if (fOut != NULL && aux <= num_frames) {
					fwrite((void *)cfilledbuffer.m.userptr,
					       cformat.fmt.pix.width *
					       cformat.fmt.pix.height *
					       2,
					       sizeof(char), fOut);
					fflush(fOut);
					aux++;
				}
				printf("Change contrast level to: %d\n",
					c_contrast.value);
				if (ioctl(cfd, VIDIOC_S_CTRL, &c_contrast) == -1)
					printf("VIDIOC_S_CTRL failed!\n");
			} else if (test == BRT_TEST) {
				c_brightness.id = V4L2_CID_BRIGHTNESS;
				c_brightness.value += step_brightness;
				if (c_brightness.value > qc_brightness.maximum)
					c_brightness.value = qc_brightness.minimum;
				if (fOut != NULL && aux <= num_frames) {
					fwrite((void *)cfilledbuffer.m.userptr,
					       cformat.fmt.pix.width *
					       cformat.fmt.pix.height *
					       2,
					       sizeof(char), fOut);
					fflush(fOut);
					aux++;
				}
				printf("Change brightness level to: %d\n",
					c_brightness.value);
				if (ioctl(cfd, VIDIOC_S_CTRL, &c_brightness) == -1)
					printf("VIDIOC_S_CTRL failed!\n");
			} else if (test == COLOR_TEST) {
				c_colorfx.id = V4L2_CID_COLORFX;
				c_colorfx.value += qc_colorfx.step;
				if (c_colorfx.value > qc_colorfx.maximum)
					c_colorfx.value = qc_colorfx.minimum;
				if (fOut != NULL && aux <= num_frames) {
					fwrite((void *)cfilledbuffer.m.userptr,
					       cformat.fmt.pix.width *
					       cformat.fmt.pix.height *
					       2,
					       sizeof(char), fOut);
					fflush(fOut);
					aux++;
				}
				printf("Change color effect to: %d\n",
					c_colorfx.value);
				if (ioctl(cfd, VIDIOC_S_CTRL, &c_colorfx) == -1)
					printf("VIDIOC_S_CTRL failed!\n");
			}
		}

		if (i == 3) {
			/* Turn on streaming for video */
			if (ioctl(vfd, VIDIOC_STREAMON, &vreqbuf.type)) {
				perror("dss VIDIOC_STREAMON");
				return -1;
			}
		}

		if (i >= 3) {
			/* De-queue the previous buffer from video driver */
			if (ioctl(vfd, VIDIOC_DQBUF, &vfilledbuffer)) {
				perror("dss VIDIOC_DQBUF");
				return;
			}

			cfilledbuffer.index = vfilledbuffer.index;
			while (ioctl(cfd, VIDIOC_QBUF, &cfilledbuffer) < 0)
				perror("cam VIDIOC_QBUF");
		}
	}
	printf("Captured and rendered %d frames!\n", i);


	printf("Restore defaults:\n");

	printf(" - Contrast = %i\n", orig_contrast);
	c_contrast.id = V4L2_CID_CONTRAST;
	c_contrast.value = qc_contrast.default_value;
	if (ioctl(cfd, VIDIOC_S_CTRL, &c_contrast) == -1)
		printf("VIDIOC_S_CTRL CONTRAST failed!\n");

	printf(" - Brightness = %i\n", orig_brightness);
	c_brightness.id = V4L2_CID_BRIGHTNESS;
	c_brightness.value = qc_brightness.default_value;
	if (ioctl(cfd, VIDIOC_S_CTRL, &c_brightness) == -1)
		printf("VIDIOC_S_CTRL BRIGHTNESS failed!\n");

	printf(" - Color = %i\n", orig_color);
	c_colorfx.id = V4L2_CID_COLORFX;
	c_colorfx.value = qc_colorfx.default_value;
	if (ioctl(cfd, VIDIOC_S_CTRL, &c_colorfx) == -1)
		printf("VIDIOC_S_CTRL COLOR failed!\n");


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

	close(cfd);
	close(vfd);
	if (fOut != NULL)
		fclose(fOut);
}
