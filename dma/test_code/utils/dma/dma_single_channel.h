/*
 * DMA Single channel transfer common functions
 *
 * The following code has the header for the common functions
 * used in the single channel transfer tests.
 *
 * History:
 * 20-01-2009	Gustavo Diaz	Initial version of the testcode
 *
 * Copyright (C) 2007-2009 Texas Instruments, Inc
 *
 * This package is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */


#include <linux/dma-mapping.h>
#include <linux/proc_fs.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <asm/io.h>
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27))
 #include <mach/dma.h>
#else
 #include <asm/arch/dma.h>
#endif

#ifndef _DMA_SINGLE_CHANNEL_H
#define _DMA_SINGLE_CHANNEL_H

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27))
    #define DMA_TEST_LITTLE_ENDIAN OMAP_DMA_LITTLE_ENDIAN
    #define DMA_TEST_BIG_ENDIAN OMAP_DMA_BIG_ENDIAN
#else
    #define DMA_TEST_LITTLE_ENDIAN LITTLE_ENDIAN
    #define DMA_TEST_BIG_ENDIAN BIG_ENDIAN
#endif


/*
 * An struct that represents the buffers used for the transfer
 */
struct dma_buffers_info{
       unsigned int src_buf; /* virtual source buffer address */
       unsigned int src_buf_phys; /* physycal source buffer address */
       unsigned int dest_buf; /* virtual destination buffer address */
       unsigned int dest_buf_phys; /* physycal destination buffer address */
       unsigned int buf_size; /* buffer size in bytes */
};

/*
 * An struct that represents a dma transfer
 */
struct dma_transfer{
       int elements_in_frame; /* number of elements in a frame */
       int frame_count; /* number of frames in a transfer block */
       int request_success; /* whether or not the dma request succeeded */
       int data_correct; /* whether or not the transfered data is correct */
       int finished; /* whether or not the transfered is finished */
       int data_type;
       int sync_mode; /* synchronization mode */
       int device_id;
       int data_burst;
       int transfer_id; /* channel number or chain id */
       int priority;
       int endian_type;
       int addressing_mode;
       struct dma_buffers_info buffers;
};

/*
 * An struct that represent a dma channel query
 */
struct dma_query{
       int element_index;
       int frame_index;
       int src_addr_counter;
       int dest_addr_counter;
};

/*
 * Function used to verify the source an destination buffers of a dma transfer
 * are equal in content
 */
int verify_buffers(struct dma_buffers_info *buffers);

/*
 * Callback function that dma framework will invoke after transfer is done
 */
void dma_callback(int transfer_id, u16 transfer_status, void *data);

/*
 * This function allocates 2 dma buffers with the same size for the source
 * and destination.
 */
int create_transfer_buffers( struct dma_buffers_info *buffers);

/*
 * Fill the source buffer with bytes using a pseudo-random value generator
 */
void fill_source_buffer(struct dma_buffers_info *buffers);

/*
 * Requests a dma transfer
 */
int request_dma(struct dma_transfer *transfer);

/*
 * Setup the source, destination and global transfer parameters
 */
void setup_dma_transfer(struct dma_transfer *transfer);

/*
 * Starts a dma transfer
 */
void start_dma_transfer(struct dma_transfer *transfer);

/*
 * Stops a dma transfer and free used resources
 */
void stop_dma_transfer(struct dma_transfer *transfer);

/*
 * Set if the test passed or not
 */
void set_test_passed(int passed);

/*
 * Creates a read proc entry in the procfs
 */
void create_dma_proc(char *proc_name);

/*
 * Removes a proc entry from the procfs
 */
void remove_dma_proc(char *proc_name);

/*
 * Queries for information about an on going dma transfer
 */
int dma_channel_query(struct dma_transfer *transfer,
     struct dma_query *query);

#endif
