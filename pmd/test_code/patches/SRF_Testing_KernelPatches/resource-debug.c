/*
 * linux/arch/arm/plat-omap/resource-debug.c
 * OMAP3 SRF test file
 *
 * Copyright (C) 2009-2010 Texas Instruments, Inc.
 * Charulatha Varadarajan <charu@ti.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 * History:
 *
 * 2009-09-17: Charulatha V         Initial code
 *
 */

#include <linux/module.h>
#include <mach/resource-debug.h>

extern int resource_access_opp_lock(int res, int delta);
extern struct omap_opp *l3_opps;
extern unsigned short enable_off_mode;
void resource_test(void);

/**
 * request_vdd2_opp - resource_request done for vdd2_opp resource
 * @dev: device address
 * @req_lvl: required level
 *
 * does a resource_request for vdd2_opp resource by giving the required
 * throughput input parameter
 *
 * Returns TEST_FAIL during failure or return values of resource_request
 */
static int request_vdd2_opp(struct device *dev, unsigned long req_lvl)
{
	int ret;
	switch (req_lvl) {
	case VDD2_OPP2:
		ret = resource_request("vdd2_opp", dev, VDD2_LEVEL2_THROUGHPUT);
		break;

	case VDD2_OPP3:
		ret = resource_request("vdd2_opp", dev, VDD2_LEVEL3_THROUGHPUT);
		break;

	default:
		printk(KERN_ERR "FAILED!!!! invalid vdd2_opp level\n");
		ret = TEST_FAIL;
	}
	return ret;
}
/**
 * min_level - Find the minimum of the given two levels
 * @a: level1
 * @b: level2
 *
 * Find the minimum of the given two levels
 *
 * Returns the minimum level
 */
static unsigned long min_level(unsigned long a, unsigned long b)
{
	return ((a <= b) ? a : b);
}

/**
 * max_level - Find the maximum of the given two levels
 * @a: level1
 * @b: level2
 *
 * Find the maximum of the given two levels
 *
 * Returns the maximum level
 */
static unsigned long max_level(unsigned long a, unsigned long b)
{
	return ((a >= b) ? a : b);
}

/**
 * min_level_1 - Find the minimum of the given four levels
 * @a: level1
 * @b: level2
 * @c: level3
 * @d: level4
 *
 * Find the minimum of the given four levels
 *
 * Returns the minimum level
 */
static unsigned long min_level_1(unsigned long a, unsigned long b,
				unsigned long c, unsigned long d)
{
	unsigned long tmp;
	tmp = ((a <= b) && (a <= c) ? a : (b <= c) ? b : c);
	return ((tmp <= d) ? tmp : d);
}

/**
 * max_level - Find the maximum of the given three levels
 * @a: level1
 * @b: level2
 * @c: level3
 *
 * Find the maximum of the given three levels
 *
 * Returns the maximum level
 */
static unsigned long max_level_1(unsigned long a, unsigned long b,
				unsigned long c)
{
	return ((a >= b) && (a >= c) ? a : (b >= c) ? b : c);
}

/**
 * resource_test_1 - Tests the resource framework basic APIs for
 *                   "opp/freq" resources
 * @res_name: Name of the resource requested
 * @req_lvl: Requested level for the resource
 *
 * Requests the "opp/freq" resource for the given level,
 * verifies if the resource's current level is same as the requested level
 * and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_1(const char *res_name, unsigned long req_lvl)
{
	int ret, cur_lvl, result = TEST_PASS;
	struct device dev;

	printk(KERN_INFO "Entry resource_test_1 \n");

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev, req_lvl);
	else
		ret = resource_request(res_name, &dev, req_lvl);

	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev resource request for "
			"%s failed with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	if (cur_lvl != req_lvl) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, (int)req_lvl);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_1 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_2 - Tests resource framework APIs when two devices requests
 *                   the same "opp/freq" resource for same or different levels
 * @res_name: Name of the resource requested
 * @req_lvl1: Device 1 level requested for the resource
 * @req_lvl2: Device 2 level requested for the resource
 *
 * Two devices requests the "opp/freq" resource for the specified levels,
 * verifies if the resource's current level is same as the maximum of
 * requested levels and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_2(const char *res_name, unsigned long req_lvl1,
			unsigned long req_lvl2)
{
	int ret, result = TEST_PASS;
	int cur_lvl, req_lvl;
	struct device dev1, dev2;

	printk(KERN_INFO "Entry resource_test_2 \n");

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev1, req_lvl1);
	else
		ret = resource_request(res_name, &dev1, req_lvl1);

	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev2, req_lvl2);
	else
		ret = resource_request(res_name, &dev2, req_lvl2);

	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	req_lvl = (int) max_level(req_lvl1, req_lvl2);
	if (cur_lvl != req_lvl) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, req_lvl);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_2 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_3 - Tests resource framework APIs when three devices requests
 *                   the same "opp/freq" resource for same or different levels
 * @res_name: Name of the resource requested
 * @req_lvl1: Device 1 level requested for the resource
 * @req_lvl2: Device 2 level requested for the resource
 * @req_lvl3: Device 3 level requested for the resource
 *
 * Three devices requests the "opp/freq" resource for the specified levels,
 * verifies if the resource's current level is same as the maximum of
 * requested levels and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_3(const char *res_name, unsigned long req_lvl1,
		unsigned long req_lvl2, unsigned long req_lvl3)
{
	int ret, result = TEST_PASS;
	int cur_lvl, req_lvl;
	struct device dev1, dev2, dev3;

	printk(KERN_INFO "Entry resource_test_3 \n");

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev1, req_lvl1);
	else
		ret = resource_request(res_name, &dev1, req_lvl1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev2, req_lvl2);
	else
		ret = resource_request(res_name, &dev2, req_lvl2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		return TEST_FAIL;
	}

	if (!strcmp(res_name, "vdd2_opp"))
		ret = request_vdd2_opp(&dev3, req_lvl3);
	else
		ret = resource_request(res_name, &dev3, req_lvl3);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev3 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		resource_release(res_name, &dev2);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	req_lvl = (int) max_level_1(req_lvl1, req_lvl2, req_lvl3);
	if (cur_lvl != req_lvl) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, req_lvl);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource release for %s failed"
			" with value %d\n", res_name, ret);
	result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource release for %s failed"
			" with value %d\n", res_name, ret);
	result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev3);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev3 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_3 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_4 - Tests the resource framework basic APIs for
 *                   "latency" resources
 * @res_name: Name of the resource requested
 * @req_lat: Requested lat for the resource
 * @ref_table: Pointer to the reference latency table for the given resource
 *
 * Requests the "latency" resource for the given level,
 * verifies if the resource's current level is same as the
 * closest lower reference level and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_4(const char *res_name, unsigned long req_lat,
			unsigned long *ref_table)
{
	int ret, i, result = TEST_PASS;
	int cur_lvl;
	struct device dev;

	printk(KERN_INFO "Entry resource_test_4 \n");

	ret = resource_request(res_name, &dev, req_lat);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);

	/* using the ref table to find the appropriate PD state */
	for (i = 0; i < 3; i++) {
		if (ref_table[i] < req_lat)
			break;
	}
	if (!enable_off_mode && i == PD_LATENCY_OFF)
		i = PD_LATENCY_RET;
	/* Inactive state is not being tested */
	else if (i == 2)
		i = PD_LATENCY_ON;

	if (cur_lvl != i) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, i);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_4 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_5 - Tests resource framework APIs when two devices requests
 *                   the same "latency" resource for same or different levels
 * @res_name: Name of the resource requested
 * @req_lat1: Device 1 latency requested for the resource
 * @req_lat2: Device 2 latency requested for the resource
 * @ref_table: Pointer to the reference latency table for the given resource
 *
 * Two devices requests the "lat" resource for the specified levels,
 * verifies if the resource's current level is same as that of the
 * closest lower reference level to the lowest level requested among the
 * two devices and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_5(const char *res_name, unsigned long req_lat1,
			unsigned long req_lat2, unsigned long *ref_table)
{
	int ret, result = TEST_PASS, i;
	struct device dev1, dev2;
	int cur_lvl, req_lat;

	printk(KERN_INFO "Entry resource_test_5 \n");

	ret = resource_request(res_name, &dev1, req_lat1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	ret = resource_request(res_name, &dev2, req_lat2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	req_lat = (int) min_level(req_lat1, req_lat2);

	/* using the ref table to find the appropriate PD state */
	for (i = 0; i < 3; i++) {
		if (ref_table[i] < req_lat)
			break;
	}
	if (!enable_off_mode && i == PD_LATENCY_OFF)
		i = PD_LATENCY_RET;
	/* Inactive state is not being tested */
	else if (i == 2)
		i = PD_LATENCY_ON;

	if (cur_lvl != i) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, i);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_5 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_6 - Tests resource framework APIs when four devices requests
 *                   the same "latency" resource for same or different levels
 * @res_name: Name of the resource requested
 * @req_lat1: Device 1 level requested for the resource
 * @req_lat2: Device 2 level requested for the resource
 * @req_lat4: Device 3 level requested for the resource
 * @req_lat4: Device 4 level requested for the resource
 * @ref_table: Pointer to the reference latency table for the given resource
 *
 * Four devices requests the "lat" resource for the specified levels,
 * verifies if the resource's current level is same as that of the
 * closest lower reference level to the lowest level requested among the
 * four devices and releases the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_6(const char *res_name, unsigned long req_lat1,
			unsigned long req_lat2, unsigned long req_lat3,
			unsigned long req_lat4, unsigned long *ref_table)
{
	int ret, result = TEST_PASS, i;
	struct device dev1, dev2, dev3, dev4;
	int cur_lvl, req_lat;

	printk(KERN_INFO "Entry resource_test_6 \n");

	ret = resource_request(res_name, &dev1, req_lat1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	ret = resource_request(res_name, &dev2, req_lat2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		return TEST_FAIL;
	}

	ret = resource_request(res_name, &dev3, req_lat3);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev3 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		resource_release(res_name, &dev2);
		return TEST_FAIL;
	}

	ret = resource_request(res_name, &dev4, req_lat4);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev4 resource request for %s failed"
			" with value %d\n", res_name, ret);
		resource_release(res_name, &dev1);
		resource_release(res_name, &dev2);
		resource_release(res_name, &dev3);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	req_lat = (int)min_level_1(req_lat1, req_lat2, req_lat3, req_lat4);

	/* using the ref table to find the appropriate PD state */
	for (i = 0; i < 3; i++) {
		if (ref_table[i] < req_lat)
			break;
	}
	if (!enable_off_mode && i == PD_LATENCY_OFF)
		i = PD_LATENCY_RET;
	/* Inactive state is not being tested */
	else if (i == 2)
		i = PD_LATENCY_ON;

	if (cur_lvl != i) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, i);
		result = TEST_FAIL;
	}

	ret = resource_release(res_name, &dev1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev1 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev2 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev3);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev3 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev4);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! dev4 resource release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_6 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test_7 - Tests the resource_refresh API
 * @res_name: Name of the resource requested ("vdd1_opp"/"vdd2_opp")
 * @req_lvl1: Requested lower level for the resource
 * @req_lvl2: Requested higher level for the resource
 *
 * Device 1 requests the resource for the given lower level,
 * locks the resource. Meanwhile device 2 requests the reource for a
 * higher level.
 * Verifies if the resource's current level is same as the requested
 * higher level after device 1 unlocks the resource
 *
 * Returns 0 on success, -1 on failure
 */
static int resource_test_7(const char *res_name, unsigned long req_lvl1,
			unsigned long req_lvl2)
{
	int ret, cur_lvl, result = TEST_PASS;
	int lock_val;
	struct device dev1, dev2;

	printk(KERN_INFO "Entry resource_test_7 \n");

	if (!strcmp(res_name, "vdd1_opp"))
		lock_val = VDD1_OPP;
	else if (!strcmp(res_name, "vdd2_opp"))
		lock_val = VDD2_OPP;
	else {
		printk(KERN_ERR "FAILED!!!! invalid resource name\n");
		return TEST_FAIL;
	}

	ret = resource_request(res_name, &dev1, req_lvl1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource1 request for %s failed"
			" with value %d\n", res_name, ret);
		return TEST_FAIL;
	}

	cur_lvl = resource_get_level(res_name);
	if (cur_lvl != req_lvl1) {
		printk(KERN_ERR "FAILED!!!! resource %s current level:%d"
			" req lvl:%d\n", res_name, cur_lvl, (int)req_lvl1);
		result = TEST_FAIL;
	}

	if (result == TEST_PASS) {
		ret = resource_access_opp_lock(lock_val, 1);
		if (ret < 0) {
			printk(KERN_ERR "FAILED!!!! resource %s lock failed"
				" with value %d\n", res_name, ret);
			result = TEST_FAIL;
		}
	}

	if (result == TEST_PASS) {
		ret = resource_request(res_name, &dev2, req_lvl2);
		if (ret) {
			printk(KERN_ERR "FAILED!!!! resource2 request %s failed"
				" with value %d\n", res_name, ret);
			ret = resource_access_opp_lock(lock_val, -1);
			if (ret < 0)
				printk(KERN_ERR "FAILED!!!! resource unlock"
					"for %s failed\n", res_name);
			result = TEST_FAIL;
		}
	}

	if (result == TEST_PASS) {
		cur_lvl = resource_get_level(res_name);
		if (cur_lvl != req_lvl1) {
			printk(KERN_ERR "FAILED!!!! %s current level:%d"
				" req lvl:%d\n", res_name, cur_lvl,
				(int)req_lvl1);
			result = TEST_FAIL;
		}

		ret = resource_access_opp_lock(lock_val, -1);
		if (ret < 0) {
			printk(KERN_ERR "FAILED!!!! resource unlock %s failed"
				" with value %d\n", res_name, ret);
			result = TEST_FAIL;
		}

		ret = resource_refresh();
		if (ret) {
			printk(KERN_ERR "FAILED!!!! resource refresh failed"
				" with value %d\n", ret);
			result = TEST_FAIL;
		}

		cur_lvl = resource_get_level(res_name);
		if (cur_lvl != req_lvl2) {
			printk(KERN_ERR "FAILED!!!! %s current level:%d"
				" req lvl:%d\n", res_name, cur_lvl,
				(int)req_lvl2);
			result = TEST_FAIL;
		}
	}

	ret = resource_release(res_name, &dev1);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource1 release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}
	ret = resource_release(res_name, &dev2);
	if (ret) {
		printk(KERN_ERR "FAILED!!!! resource2 release for %s failed"
			" with value %d\n", res_name, ret);
		result = TEST_FAIL;
	}

	if (!result)
		printk(KERN_INFO "resource_test_7 PASSED for %s\n", res_name);
	return result;
}

/**
 * resource_test - Test the shared resource framework for different resources
 *
 * Test the shared resource framework APIs for different resources and
 * different scenarios
 *
 */
void resource_test()
{
	int i, j, k, ret, result = TEST_PASS;

	printk(KERN_INFO "Entry resource_test \n"
			"SRF test case assumes that\n"
			"scaling_governor is in ondemand state\n");

	/* Test basic SRF APIs for performance type resources */
	for (i = 0; i < NO_OF_OPP_FREQ_RESOURCES; i++) {
		for (j = 0; j < NO_OF_TEST_VALUES; j++) {
			ret = resource_test_1(res_names[i],
					res_test_table[i][j]);
			if (ret)
				result = ret;
		}
	}
	if (!result)
		printk(KERN_INFO "Resource Test1 Passed for all "
			"OPP/Freq resources\n");
	else
		printk(KERN_ERR "Resource Test1 FAILED!!!! for"
			" OPP/Freq resource(s)\n");

	/* Test basic SRF APIs for core/MPU latency type resources */
	result = TEST_PASS;
	for (i = (NO_OF_OPP_FREQ_RESOURCES + NO_OF_PWRDM_LAT_RESOURCES);
		i < NO_OF_RESOURCES; i++) {
		for (j = 0; j < NO_OF_TEST_VALUES; j++) {
			ret = resource_test_1(res_names[i],
					res_test_table[i][j]);
			if (ret)
				result = ret;
		}
	}
	if (!result)
		printk(KERN_INFO "Resource Test1 Passed for all "
			"MPU/core latency resources\n");
	else
		printk(KERN_ERR "Resource Test1 FAILED!!!! for"
			" MPU/core latency resource(s)\n");

	/* Test two devices resource sharing for performance type resources */
	result = TEST_PASS;
	for (i = 0; i < NO_OF_OPP_FREQ_RESOURCES; i++) {
		for (j = 0; j < NO_OF_TEST_VALUES; j++) {
			for (k = 0; k < NO_OF_TEST_VALUES; k++) {
				ret = resource_test_2(res_names[i],
					res_test_table[i][j],
					res_test_table[i][k]);
				if (ret)
					result = ret;
			}
		}
	}
	if (!result)
		printk(KERN_INFO "Resource Test2 Passed for all "
			"OPP/Freq resources\n");
	else
		printk(KERN_ERR "Resource Test2 FAILED!!!!\n");

	/* Test three devices resource sharing for performance type resources */
	result = TEST_PASS;
	for (i = 0; i < NO_OF_OPP_FREQ_RESOURCES; i++) {
		ret = resource_test_3(res_names[i],
					res_test_table[i][0],
					res_test_table[i][1],
					res_test_table[i][2]);
		if (ret)
			result = ret;
	}
	if (!result)
		printk(KERN_INFO "Resource Test3 Passed for all "
			"OPP/Freq resources\n");
	else
		printk(KERN_ERR "Resource Test3 FAILED!!!!\n");

	/* Test basic SRF APIs for power domain latency type resources */
	result = TEST_PASS;
	for (i = NO_OF_OPP_FREQ_RESOURCES; i < NO_OF_OPP_FREQ_RESOURCES +
					NO_OF_PWRDM_LAT_RESOURCES; i++) {
		for (j = 0; j < NO_OF_TEST_VALUES; j++) {
			ret = resource_test_4(res_names[i],
					res_test_table[i][j],
					&lat_ref_table[i][0]);
			if (ret)
				result = ret;
		}
	}
	if (!result)
		printk(KERN_INFO "Resource Test4 Passed for all "
			"pwrdm resources\n");
	else
		printk(KERN_ERR "Resource Test4 FAILED!!!!\n");

	/* Test two devices resource sharing for pwrdmn lat type resources */
	result = TEST_PASS;
	for (i = NO_OF_OPP_FREQ_RESOURCES; i < NO_OF_OPP_FREQ_RESOURCES +
					NO_OF_PWRDM_LAT_RESOURCES; i++) {
		for (j = 0; j < NO_OF_TEST_VALUES; j++) {
			for (k = 0; k < NO_OF_TEST_VALUES; k++) {
				ret = resource_test_5(res_names[i],
					res_test_table[i][j],
					res_test_table[i][k],
					&lat_ref_table[i][0]);
				if (ret)
					result = ret;
			}
		}
	}
	if (!result)
		printk(KERN_INFO "Resource Test5 Passed for all "
			"pwrdm resources\n");
	else
		printk(KERN_ERR "Resource Test5 FAILED!!!!\n");

	/* Test four devices resource sharing for pwrdmn lat type resources */
	result = TEST_PASS;
	for (i = NO_OF_OPP_FREQ_RESOURCES; i < NO_OF_OPP_FREQ_RESOURCES +
					NO_OF_PWRDM_LAT_RESOURCES; i++) {
		ret = resource_test_6(res_names[i],
					res_test_table[i][0],
					res_test_table[i][1],
					res_test_table[i][2],
					res_test_table[i][3],
					&lat_ref_table[i][0]);
		if (ret)
			result = ret;
	}
	if (!result)
		printk(KERN_INFO "Resource Test6 Passed for all "
			"pwrdm resources\n");
	else
		printk(KERN_ERR "Resource Test6 FAILED!!!!\n");

	/* Test resource_refresh API for vdd1_opp resource */
	result = resource_test_7("vdd1_opp", VDD1_OPP3,
					VDD1_OPP5);
	if (!result)
		printk(KERN_INFO "Resource Test7 Passed for vdd1_opp \n");
	else
		printk(KERN_ERR "Resource Test7 FAILED!!!!\n");

	return;
}
EXPORT_SYMBOL(resource_test);
