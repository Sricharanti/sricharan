#include <linux/module.h>
#include <linux/irq.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/irq.h>
#include <linux/cpu.h>
#include <asm/irq.h>
#include <linux/version.h>
#include <linux/gpio.h>
#include <linux/io.h>

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27) && LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,31))
 #include <mach/hardware.h>
 #include <mach/control.h>
 #include <mach/irqs.h>
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,32)
#include </home/a0393807/kernel/linux_feature_tree/linux-omap/arch/arm/mach-omap2/soc.h>
#else
 #include <asm/arch/hardware.h>
 #include <asm/arch/control.h>
 #include <asm/arch/irqs.h>
#endif

#include <linux/proc_fs.h>

#include <linux/sched.h>
#include <linux/kthread.h>
#include <linux/unistd.h>

#define PROC_FILE "driver/gpio_test_result"

#ifndef CONFIG_ARCH_OMAP5
#define cpu_is_omap54xx() NULL
#endif

static uint test;
static uint gpio;
static uint value;
static uint request_flag = 0;
static uint input_direction_flag = 0;
static uint output_direction_flag = 0;
static uint test_passed = 1;
static uint error_flag_1 = 1, error_flag_2 = 1, error_flag_3 = 1;
static uint iterations = 1;

/* To ensure that we protect the global variable used in test case */
static DEFINE_SPINLOCK(gpio_lock);
unsigned int msleep( unsigned int milliseconds );

module_param(iterations, int, S_IRUGO|S_IWUSR);
module_param(test, int, S_IRUGO|S_IWUSR);
module_param(gpio, int, S_IRUGO|S_IWUSR);
module_param(value, int, S_IRUGO|S_IWUSR);

static void gpio_test_request(void)
{
	int ret;
	printk(KERN_INFO "Reserving GPIO line %d\n", gpio);
	ret = gpio_request(gpio, "titan_test");
	if (!ret) {
		spin_lock(&gpio_lock);
		request_flag = 1;
		spin_unlock(&gpio_lock);
		printk(KERN_INFO "Succesfully Reserved GPIO %d\n", gpio);
	} else
		printk(KERN_ERR "GPIO line %d request: failed!\n", gpio);
}

/* gpio_free does not return any value */
static void gpio_test_free(void)
{
	gpio_free(gpio);
	printk(KERN_INFO "Freeing GPIO line %d\n", gpio);
}

static void gpio_test_direction_input(void)
{
	if (!gpio_direction_input(gpio)) {
		input_direction_flag = 1;
		printk(KERN_INFO "Input configuration succesful\n");
	} else {
		error_flag_1 = 0;
		printk(KERN_ERR "Input configuration failed\n");
	}
}

static void gpio_test_direction_output(void)
{
	if (!gpio_direction_output(gpio, value)) {
		output_direction_flag = 1;
		printk(KERN_INFO "Output configuration succesful\n");
	} else {
		error_flag_2 = 0;
		printk(KERN_ERR "Output configuration failed\n");
	}
}

static void gpio_test_read(void)
{
	int ret;

	ret = gpio_get_value(gpio);      /* Reading the value of pin # */
	printk(KERN_INFO "Value of pin # %d = %d\n", gpio, ret);
	if (ret < 0)
		error_flag_3 = 0;
}

/* gpio_set_value does not return any value */
static void gpio_test_write(void)
{
	printk(KERN_INFO "Writing to GPIO line %d Value %d\n", gpio, value);
	gpio_set_value(gpio, value);
}

static void gpio_test_irq(void)
{
	int ret, irq;

	irq = gpio_to_irq(gpio);
	if (irq >= 0)
		printk(KERN_INFO "The GPIO Line %d successfully mapped "
				"to IRQ number %d\n", gpio, irq);
	else {
		error_flag_1 = 0;
		printk(KERN_ERR "Error in mapping GPIO Line %d to IRQ, "
				"Error number: %d\n", gpio, irq);
	}

	ret = irq_set_irq_type(irq, IRQ_TYPE_EDGE_FALLING);
	if (!ret)
		printk(KERN_INFO "Succesfull in Setting IRQ %i for GPIO "
				"Line %i type: FALLING\n", irq, gpio);
	else {
		error_flag_2 = 0;
		printk(KERN_ERR "Error in Setting IRQ %i for GPIO Line %i "
				"type: FALLING\n", irq, gpio);
	}

	ret = irq_set_irq_type(irq, IRQ_TYPE_EDGE_RISING);
	if (!ret)
		printk(KERN_INFO "Succesfull in Setting IRQ %i for GPIO "
				"Line %i type: RISING\n", irq, gpio);
	else {
		error_flag_3 = 0;
		printk(KERN_ERR "Error in Setting IRQ %i for GPIO Line %i "
				"type: RISING\n", irq, gpio);
	}
}

static int gpio_keep_reading(void *no_of_iterations)
{
	int loop;
	for (loop = 0; loop < iterations; loop++) {
		gpio_test_request();
		spin_lock(&gpio_lock);
		if (request_flag) {
			request_flag = 0;
			spin_unlock(&gpio_lock);
			printk(KERN_INFO "Running on %d ",smp_processor_id() );
			gpio_test_direction_input();
			if (input_direction_flag)
				gpio_test_read();
			gpio_test_free();
            }
        else {
			spin_unlock(&gpio_lock);
		}
    }
    return 0;
}

static void gpio_test7(void)
{
	int ret, request_status[32], i, j;
	u32 *bank_base_addr[8], mod_status, bank_status;
	int bank_count;

	if (cpu_is_omap34xx()) {
		/* Initialise base addresses for each bank */
		bank_base_addr[0] = ioremap_nocache(0x48310000, SZ_4K);
		bank_base_addr[1] = ioremap_nocache(0x49050000, SZ_4K);
		bank_base_addr[2] = ioremap_nocache(0x49052000, SZ_4K);
		bank_base_addr[3] = ioremap_nocache(0x49054000, SZ_4K);
		bank_base_addr[4] = ioremap_nocache(0x49056000, SZ_4K);
		bank_base_addr[5] = ioremap_nocache(0x49058000, SZ_4K);
	} else if (cpu_is_omap44xx()) {
		bank_base_addr[0] = ioremap_nocache(0x4a310000, SZ_4K);
		bank_base_addr[1] = ioremap_nocache(0x48055000, SZ_4K);
		bank_base_addr[2] = ioremap_nocache(0x48057000, SZ_4K);
		bank_base_addr[3] = ioremap_nocache(0x48059000, SZ_4K);
		bank_base_addr[4] = ioremap_nocache(0x4805B000, SZ_4K);
		bank_base_addr[5] = ioremap_nocache(0x4805D000, SZ_4K);
	} else if (soc_is_omap54xx() || soc_is_dra7xx()) {
		bank_base_addr[0] = ioremap_nocache(0x4ae10000, SZ_4K);
		bank_base_addr[1] = ioremap_nocache(0x48055000, SZ_4K);
		bank_base_addr[2] = ioremap_nocache(0x48057000, SZ_4K);
		bank_base_addr[3] = ioremap_nocache(0x48059000, SZ_4K);
		bank_base_addr[4] = ioremap_nocache(0x4805B000, SZ_4K);
		bank_base_addr[5] = ioremap_nocache(0x4805D000, SZ_4K);
		bank_base_addr[6] = ioremap_nocache(0x48051000, SZ_4K);
		bank_base_addr[7] = ioremap_nocache(0x48053000, SZ_4K);

	} else {
		printk(KERN_ERR "This GPIO test case not supported"
				" for this architecture\n");
		return;
	}

	if (soc_is_omap54xx() || soc_is_dra7xx())
		bank_count = 8;
	else
		bank_count = 6;

	for (i = 0; i < bank_count; i++) {
		bank_status = 0;
		for (j = 0; j < 32; j++) {
			ret = gpio_request(j+i*32, "titan_test");
			if (!ret)
				request_status[j] = 1;
			else {
				request_status[j] = 0;
				printk(KERN_INFO "GPIO %d Busy\n", j+i*32);
				bank_status = 1;
			}
		}
		for (j = 0; j < 32; j++) {
			if (request_status[j])
				gpio_free(j+i*32);
		}
		/* Read GPIO_CTRL to verify the module status */
		if (cpu_is_omap34xx()) {
			mod_status = __raw_readl(bank_base_addr[i] + 0xc)
						& 0x1;
		} else if (cpu_is_omap44xx() || soc_is_omap54xx() || soc_is_dra7xx()) {
			if (bank_status)
				mod_status =
				__raw_readl(bank_base_addr[i] + 0x130) & 0x1;
			else
				mod_status = 1;
		}
		if (mod_status)
			printk(KERN_INFO "GPIO Module %d disable Success"
				"\n\n", i);
		else if (!bank_status) {
			test_passed = 0;
			printk(KERN_INFO "GPIO Module %d disable Failed"
				"\n\n", i);
		}
		else
			printk(KERN_INFO "GPIO Module %d not free\n\n", i);
	}
}

static void gpio_test(void)
{
		int loop;
		struct task_struct *p1, *p2, *p3, *p4;
		int x;

		switch (test) {

		case 1: /* Reserve and free GPIO Line */
			gpio_test_request();
			if (request_flag)
				gpio_test_free();
			break;

		case 2: /* Set GPIO input/output direction */
			gpio_test_request();
			if (request_flag) {
				gpio_test_direction_input();
				gpio_test_direction_output();
				gpio_test_free();
			}
			break;

		case 3: /* GPIO read */
			gpio_test_request();
			if (request_flag) {
				gpio_test_direction_input();
				if (input_direction_flag)
					gpio_test_read();
				gpio_test_free();
			}
			break;

		case 4: /* GPIO write */
			gpio_test_request();
			if (request_flag) {
				gpio_test_direction_output();
				if (output_direction_flag)
					gpio_test_write();
				gpio_test_free();
			}
			break;

		case 5:/* configure the interrupt edge \
				sensitivity (rising, falling) */
			gpio_test_request();
			if (request_flag) {
				gpio_test_irq();
				gpio_test_free();
			}
			break;

#if defined(CONFIG_ARCH_OMAP4) || defined(CONFIG_ARCH_OMAP5)
		case 6: /* GPIO read */
			for (loop = 0; loop < iterations; loop++) {
				gpio_test_request();
				if (request_flag) {
                                        printk(KERN_INFO "Running on %d ",smp_processor_id() );
					gpio_test_direction_input();
					if (input_direction_flag)
						gpio_test_read();
					gpio_test_free();
				}
			}
			break;

		case 7: /* GPIO write */
			for (loop = 0; loop < iterations; loop++) {
				gpio_test_request();
				if (request_flag) {
					printk(KERN_INFO "Running on %d ",smp_processor_id() );
					gpio_test_direction_output();
					if (output_direction_flag)
						gpio_test_write();
					gpio_test_free();
				}
			}
			break;

		case 8: /* thread */
			p1 = kthread_create(gpio_keep_reading, NULL , "gpiotest/0");
			p2 = kthread_create(gpio_keep_reading, NULL , "gpiotest/1");
			kthread_bind(p1, 0);
			kthread_bind(p2, 1);
			x = wake_up_process(p1);
			x = wake_up_process(p2);
			break;
#endif
		case 9:/* Verify if GPIO module disable happens if all \
				GPIOs in the module are inactive */
			gpio_test7();
			break;

		case 10:/* Request for same GPIO twice and free \
				the GPIO */
			gpio_test_request();
			if (request_flag) {
				request_flag = 0;
				printk(KERN_INFO "Requesting same GPIO again");
				gpio_test_request();
				if (request_flag)
					test_passed = 0;
				gpio_test_free();
			}
			break;
		case 11:
			for (loop = 0; loop < 500; loop++) {
				gpio_test_request();
				if (request_flag) {

					gpio_test_direction_output();
					if (output_direction_flag)
						gpio_test_write();

					gpio_test_direction_input();
					if (input_direction_flag)
						gpio_test_read();
					gpio_test_free();
				} else
					break;
			}
			break;
		case 13: /* thread */
			p1 = kthread_create(gpio_keep_reading, NULL ,
						"gpiotest/0");
			p2 = kthread_create(gpio_keep_reading, NULL ,
						"gpiotest/1");
			p3 = kthread_create(gpio_keep_reading, NULL ,
						"gpiotest/3");
			p4 = kthread_create(gpio_keep_reading, NULL ,
						"gpiotest/4");
			x = wake_up_process(p1);
			x = wake_up_process(p2);
			x = wake_up_process(p3);
			x = wake_up_process(p4);
			break;
		case 12:
			break;
		default:
			printk(KERN_INFO "Test option not available.\n");
	}

	/* On failure of a testcase, one of the three error flags set to 0
	 * if a gpio line request fails it is not considered as a failure
	 * set test_passed =0 for failure
	 */
	if (!(error_flag_1 && error_flag_2 && error_flag_3))
		test_passed = 0;
}

/*
 * The read proc entry returns passed or failed,
 * according to the value of test_passed.
 */

static int gpio_read_proc(char *buf, char **start, off_t offset,
				int count, int *eof, void *data)
{
	int len;

	if (test_passed)
		len = sprintf(buf, "Test PASSED\n");
	else
		len = sprintf(buf, "Test FAILED\n");

	return len;
}

/*
 * Creates a read proc entry in the procfs
 */
void create_gpio_proc(char *proc_name)
{
	proc_create_data(proc_name, 0, NULL, gpio_read_proc, NULL);
}

/*
 * Removes a proc entry from the procfs
 */
void remove_gpio_proc(char *proc_name)
{
	remove_proc_entry(proc_name, NULL);
}

static int __init gpio_test_init(void)
{
	printk(KERN_INFO "\nGPIO Test Module Initialized\n\n");
	/* Create the proc entry */
	create_gpio_proc(PROC_FILE);
	gpio_test();
	return 0;
}

static void __exit gpio_test_exit(void)
{
	/* This sleep is to ensure that both the asynchronous threads run to
	 * completion before we exit the process, else we might exit before
	 * threads run to completion resulting in a crash
	 */
	msleep (100);
	/* Remove the proc entry */
	remove_gpio_proc(PROC_FILE);
	printk(KERN_INFO "\nGPIO Test Module Removal\n\n");
}

module_init(gpio_test_init);
module_exit(gpio_test_exit);

MODULE_AUTHOR("Texas Instruments");
MODULE_DESCRIPTION("GPIO Test Driver");
MODULE_LICENSE("GPL");
