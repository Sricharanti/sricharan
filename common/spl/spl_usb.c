/*
 * (C) Copyright 2013
 * Texas Instruments, <www.ti.com>
 *
 * Dan Murphy <dmurphy@ti.com>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 *
 * Derived work from spl_mmc.c
 */

#include <common.h>
#include <spl.h>
#include <asm/u-boot.h>
#include <usb.h>
#include <fat.h>
#include <version.h>
#include <image.h>

DECLARE_GLOBAL_DATA_PTR;

#ifdef CONFIG_USB_STORAGE
static int usb_stor_curr_dev = -1; /* current device */
#endif

static int usb_load_image_raw(block_dev_desc_t *stor_dev, unsigned long sector)
{
	unsigned long err;
	u32 image_size_sectors;
	struct image_header *header;

	header = (struct image_header *)(CONFIG_SYS_TEXT_BASE -
						sizeof(struct image_header));

	/* read image header to find the image size & load address */
	err = stor_dev->block_read(usb_stor_curr_dev, sector, 1, (ulong *)header);
	if (err == 0)
		goto end;

	if (image_get_magic(header) != IH_MAGIC)
		return -1;

	spl_parse_image_header(header);

	image_size_sectors = spl_image.size;

	/* Read the header too to avoid extra memcpy */
	err = stor_dev->block_read(usb_stor_curr_dev, sector,
				image_size_sectors, (void *)spl_image.load_addr);

end:
#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
	if (err == 0)
		printf("spl: USB blk read err - %lu\n", err);
#endif
	return (err == 0);

}

#ifdef CONFIG_SPL_OS_BOOT
static int usb_load_image_raw_os(struct usb_device *usb_dev)
{
	return -1;
}
#endif

#ifdef CONFIG_SPL_FAT_SUPPORT
static int usb_load_image_fat(const char *filename)
{
	int err;
	struct image_header *header;

	header = (struct image_header *)(CONFIG_SYS_TEXT_BASE -
						sizeof(struct image_header));

	err = file_fat_read(filename, header, sizeof(struct image_header));
	if (err <= 0)
		goto end;

	spl_parse_image_header(header);

	err = file_fat_read(filename, (u8 *)spl_image.load_addr, 0);

end:
#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
	if (err <= 0)
		printf("spl: error reading image %s, err - %d\n",
		       filename, err);
#endif

	return (err <= 0);
}

#ifdef CONFIG_SPL_OS_BOOT
static int usb_load_image_fat_os(struct usb_device *usb_dev)
{
	int err;

	err = file_fat_read(CONFIG_SPL_FAT_LOAD_ARGS_NAME,
			    (void *)CONFIG_SYS_SPL_ARGS_ADDR, 0);
	if (err <= 0) {
#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
		printf("spl: error reading image %s, err - %d\n",
		       CONFIG_SPL_FAT_LOAD_ARGS_NAME, err);
#endif
		return -1;
	}

	return usb_load_image_fat(CONFIG_SPL_FAT_LOAD_KERNEL_NAME);
}
#endif

#endif

void spl_usb_load_image(void)
{
	struct usb_device *usb_dev;
	int err;
	u32 boot_mode;
	block_dev_desc_t *stor_dev;

	usb_stop();
	err = usb_init();
	if (err) {
#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
		printf("spl: usb init failed: err - %d\n", err);
#endif
		hang();
	} else {
#ifdef CONFIG_USB_STORAGE
		/* try to recognize storage devices immediately */
		usb_stor_curr_dev = usb_stor_scan(1);
		stor_dev = usb_stor_get_dev(usb_stor_curr_dev);
#endif
	}

	boot_mode = spl_boot_mode();
	if (boot_mode == USB_MODE_RAW) {
		debug("boot mode - RAW\n");
#ifdef CONFIG_SPL_OS_BOOT
		if (spl_start_uboot() || usb_load_image_raw_os(usb_dev))
#endif
		err = usb_load_image_raw(stor_dev,
					 CONFIG_SYS_USB_MODE_U_BOOT_SECTOR);
#ifdef CONFIG_SPL_FAT_SUPPORT
	} else if (boot_mode == USB_MODE_FAT) {
		debug("boot mode - FAT\n");

		err = fat_register_device(stor_dev,
				CONFIG_SYS_USB_FAT_BOOT_PARTITION);
		if (err) {
	#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
			printf("spl: fat register err - %d\n", err);
	#endif
			hang();
		}

#ifdef CONFIG_SPL_OS_BOOT
		if (spl_start_uboot() || usb_load_image_fat_os(usb_dev))
#endif
		err = usb_load_image_fat(CONFIG_SPL_FAT_LOAD_PAYLOAD_NAME);
		if (err) {
			puts("Error loading USB device\n");
			hang();
		}
#endif
	} else {
#ifdef CONFIG_SPL_LIBCOMMON_SUPPORT
		puts("spl: wrong USB boot mode\n");
#endif
		hang();
	}

	if (err)
		hang();
}
