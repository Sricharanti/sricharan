/*
 * Dma descriptor autoloading Test Module
 *
 * Copyright (C) 2009 Texas Instruments, Inc.
 *
 * This package is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include <linux/sched.h>
#include <linux/kthread.h>
#include <linux/syscalls.h>
#include "dma_single_channel.h"

/********************** GENERAL VARS *****************/
#define num_elements_in_list (15)
#define PROC_FILE  "driver/dma_dload_thread_access"
#define PAUSE_AT_ELEMENT (4)

#define test_element_size 100
int maximum_transfers = 5;	/* max transfers per channel */
int buf_size = PAGE_SIZE;	/* Buffer size for each channel */

int prio = -1;
int test_result;

struct tlist_transfer {
	/* Source */
	unsigned int bsptest_dma_src_addr[num_elements_in_list];
	unsigned int bsptest_dma_src_addr_phy[num_elements_in_list];
	unsigned int transfer_sizes[num_elements_in_list];
	unsigned int total_num_elements;
	/* Dest */
	unsigned int *bsptest_dma_dst_addr;
	unsigned int *bsptest_dma_dst_addr_phy;
	int sglist_id;
	struct omap_dma_sglist_node *user_sglist;
};
static struct tlist_transfer tls1, tls2;

#define TOTAL_TRANSFERR_WORD  (num_elements_in_list*test_element_size)
#define TOTAL_TRANSFER_BYTES  (TOTAL_TRANSFERR_WORD*4)
static struct omap_dma_channel_params transfer_params = {
	.data_type = OMAP_DMA_DATA_TYPE_S32,	/* data type 8,16,32 */
	.elem_count = 0, /* CEN set by descriptor */
	.frame_count = 1,/* CFN set by descriptor */
	.src_amode = OMAP_DMA_AMODE_POST_INC,
	.src_start = 0,	/* source address : physical:set by descriptor */
	.src_ei = 0,	/* source element index :set by descriptor */
	.src_fi = 0,	/* source frame index set by descriptor*/
	.dst_amode = OMAP_DMA_AMODE_POST_INC,
	.dst_start = 0,		/* dest address : physical:set by descriptor */
	.dst_ei = 0,		/* dest element index:set by descriptor */
	.dst_fi = 0,		/* dest frame index :set by descriptor*/
	.trigger = OMAP_DMA_NO_DEVICE,
		/* trigger attached if the channel is synchronized */
	.sync_mode = OMAP_DMA_SYNC_ELEMENT,
		/* sync on element, frame , block or packet */
	.src_or_dst_synch = 0x0,
		/* source synch(1) or destination synch(0) */
	.ie = 0,		/* interrupt enabled */
	.burst_mode = OMAP_DMA_DATA_BURST_4,
};


/********************** TEST LOGIC *****************/
static int verify_dest_buffer(struct tlist_transfer *tl, int nelems)
{
	int j, i;
	char *src1;
	char *dst1;

	dst1 = (char *)tl->bsptest_dma_dst_addr;
	src1 = (char *)tl->bsptest_dma_src_addr[0];

	for (i = 0; i < nelems; i++) {
		src1 = (char *)tl->bsptest_dma_src_addr[i];
		for (j = 0 ; j < tl->transfer_sizes[i] * 4; j++) {
			if (*src1 != *dst1) {
				printk(KERN_ERR "Data doesn't match at buff %d, byte %d",
					i, j);
				return -1;
			}
			src1++;
			dst1++;
		}
	}

	printk(KERN_INFO "Verifcation succeed for %d transfers\n", nelems);
	return 0;
}

static void dma_sglist_cb_final(int sglistid, u16 ch_status, void *data)
{
	int ncur = omap_get_completed_sglist_nodes(sglistid);

	printk(KERN_INFO "Final callback status %x, ncur=%d", ch_status, ncur);
	if (verify_dest_buffer(data, num_elements_in_list) == 0)
		printk(KERN_INFO "Test PASSED\n");
}

static void dma_sglist_cb_inter(int sglistid, u16 ch_status, void *data)
{
	int pausestate;
	int stat;
	int ncur = omap_get_completed_sglist_nodes(sglistid);

	pausestate = omap_dma_sglist_is_paused(sglistid);
	printk(KERN_INFO "Inter callbk status=%x, ncur=%d pausestate=%d \n ",
		ch_status, ncur, pausestate);
	stat = verify_dest_buffer(data, PAUSE_AT_ELEMENT);
	if (stat) {
		printk(KERN_INFO "Test FAILED\n");
		return;
	}
	omap_set_dma_callback(sglistid, dma_sglist_cb_final, data);
	omap_resume_dma_sglist_transfers(sglistid, -1);
}

static void dmatest_populate_sglist(struct tlist_transfer *ptls,
		int nelem)
{
	struct omap_dma_sglist_node *listelem = NULL;
	int i;
	struct omap_dma_sglist_node *sglist = ptls->user_sglist;

	listelem = sglist;
	listelem->desc_type = OMAP_DMA_SGLIST_DESCRIPTOR_TYPE2a;
	listelem->num_of_elem = ptls->transfer_sizes[0];

	listelem->flags = OMAP_DMA_LIST_SRC_VALID | OMAP_DMA_LIST_DST_VALID;
	listelem->sg_node.t2a.src_addr = (int)ptls->bsptest_dma_src_addr_phy[0];
	listelem->sg_node.t2a.dst_addr = (int) ptls->bsptest_dma_dst_addr_phy;
	listelem->sg_node.t2a.cfn_fn = 1;
	listelem->sg_node.t2a.cicr = 0x922;
	listelem->sg_node.t2a.dst_elem_idx = 0;
	listelem->sg_node.t2a.src_elem_idx = 1;
	listelem->sg_node.t2a.dst_frame_idx_or_pkt_size = 0;
	listelem->sg_node.t2a.src_frame_idx_or_pkt_size = 1;
	for (i = 1; i < nelem; i++) {
		listelem = listelem->next;
		listelem->desc_type = OMAP_DMA_SGLIST_DESCRIPTOR_TYPE3b;
		listelem->num_of_elem = ptls->transfer_sizes[i];
		listelem->sg_node.t3b.src_or_dest_addr =
			(int) ptls->bsptest_dma_src_addr_phy[i];
		listelem->flags = OMAP_DMA_LIST_SRC_VALID;
	}
}

static int dmasglist_test1(void *info)
{
	int rc;
	int i;
	struct tlist_transfer *tls = (struct tlist_transfer *)info;
	int *bsptest_dma_src_addr = tls->bsptest_dma_src_addr;
	int *bsptest_dma_src_addr_phy = tls->bsptest_dma_src_addr_phy;
	int *bsptest_dma_dst_addr = tls->bsptest_dma_dst_addr;
	int *bsptest_dma_dst_addr_phy = tls->bsptest_dma_dst_addr_phy;
	int sglist_id = tls->sglist_id;
	struct omap_dma_sglist_node *user_sglist = tls->user_sglist;

	/* fill a test pattern into source elements */
	for (i = 0; i < num_elements_in_list; ++i) {
		tls->transfer_sizes[i] = (i + 10) * test_element_size;
		bsptest_dma_src_addr[i] =
			(unsigned int) dma_alloc_coherent(NULL,
					tls->transfer_sizes[i] * 4,
					&(bsptest_dma_src_addr_phy[i]), 0);
		memset((void *)bsptest_dma_src_addr[i], i+0x41,
			tls->transfer_sizes[i] * 4);
		printk(KERN_INFO "\n Scatter src %d ptr = %x, phy=%x",
			i, bsptest_dma_src_addr[i],
			bsptest_dma_src_addr_phy[i]);
		tls->total_num_elements += tls->transfer_sizes[i];
	}

	/* Debug Block */
	{
		unsigned int x, y;
		x = *(int *)(bsptest_dma_src_addr[0]);
		y = *(int *)(bsptest_dma_src_addr[1]);
		printk("\n Src data pattern %x %x", x, y);
	}
	bsptest_dma_dst_addr = dma_alloc_coherent(NULL,
		tls->total_num_elements * 4,
		(dma_addr_t *)&bsptest_dma_dst_addr_phy, 0);

	/* Clean up the destination for verification */
	memset(bsptest_dma_dst_addr, 0xFF,
			tls->total_num_elements * 4);

	printk("\n Gather Dest ptr =%x, phy=%x", (int) bsptest_dma_dst_addr,
			(int)bsptest_dma_dst_addr_phy);
	tls->bsptest_dma_dst_addr = bsptest_dma_dst_addr;
	tls->bsptest_dma_dst_addr_phy = bsptest_dma_dst_addr_phy;

	rc = omap_request_dma_sglist(OMAP_DMA_NO_DEVICE,
			"SGlist transfer", dma_sglist_cb_final,
			&sglist_id, num_elements_in_list, &user_sglist);
	if (rc)
		return rc;
	if (NULL == user_sglist)
		return -ENOBUFS;
	tls->user_sglist = user_sglist;
	tls->sglist_id = sglist_id;
	dmatest_populate_sglist(tls, num_elements_in_list);
	rc = omap_set_dma_sglist_params(sglist_id,
			user_sglist, &transfer_params);
	if (rc)
		return rc;

	omap_dma_set_prio_lch(sglist_id, DMA_CH_PRIO_HIGH, DMA_CH_PRIO_HIGH);
	omap_dma_set_sglist_fastmode(sglist_id, 1);
	omap_set_dma_callback(sglist_id, dma_sglist_cb_inter, tls);

	rc = omap_start_dma_sglist_transfers(sglist_id, PAUSE_AT_ELEMENT);

	return rc;
}

static void __exit dmatest_cleanup(void)
{
	int i;
	dma_free_coherent(NULL, tls1.total_num_elements * 4,
		tls1.bsptest_dma_dst_addr, tls1.bsptest_dma_dst_addr_phy);
	for (i = 0; i < num_elements_in_list; ++i)
		dma_free_coherent(NULL,
				tls1.transfer_sizes[i] * 4,
				(void *)tls1.bsptest_dma_src_addr[i],
				(void *)tls1.bsptest_dma_src_addr_phy[i]);
	i = omap_release_dma_sglist(tls1.sglist_id);
	dma_free_coherent(NULL, tls2.total_num_elements * 4,
		tls2.bsptest_dma_dst_addr, tls2.bsptest_dma_dst_addr_phy);
	for (i = 0; i < num_elements_in_list; ++i)
		dma_free_coherent(NULL,
				tls2.transfer_sizes[i] * 4,
				(void *)tls2.bsptest_dma_src_addr[i],
				(void *)tls2.bsptest_dma_src_addr_phy[i]);
	i = omap_release_dma_sglist(tls2.sglist_id);
}

static int __init dmatest_init(void)
{
	int ret = 0;
	struct task_struct *p1, *p2;
	int x;

	test_result = 0;

	/* Init channel independent config parameters */
	omap_dma_set_global_params(DMA_DEFAULT_ARB_RATE,
				DMA_DEFAULT_FIFO_DEPTH,
				DMA_THREAD_RESERVE_ONET |
				DMA_THREAD_FIFO_25);
	p1 = kthread_create(dmasglist_test1, &tls1,
			"dma_dload_thread/0");
	p2 = kthread_create(dmasglist_test1, &tls2,
			"dma_dload_thread/1");
	kthread_bind(p1, 0);
	kthread_bind(p2, 1);
	x = wake_up_process(p1);
	x = wake_up_process(p2);

	return ret;
}

module_init(dmatest_init);
module_exit(dmatest_cleanup);
MODULE_AUTHOR("Texas Instruments");
MODULE_LICENSE("GPL");
