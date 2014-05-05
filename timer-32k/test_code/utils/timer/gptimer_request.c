#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/irq.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/version.h>
#include <linux/clk.h>
#include <linux/types.h>
#include <linux/io.h>
#include <linux/irqdesc.h>
#include <linux/irqdomain.h>
#include <linux/debugfs.h>
#include <linux/kthread.h>
#include <linux/sched.h>
#include <linux/platform_device.h>
#include <linux/of_irq.h>

MODULE_DESCRIPTION("CB TEST MODULE");
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("SRICHARAN");

#define MAX_IRQS 192

static struct platform_device *platdev[MAX_IRQS];
static int used_irqs[MAX_IRQS];
static struct irq_desc *descs[MAX_IRQS];
static struct dentry *d;
static u32 omap_cb_test_all;
static u32 stress;

static const struct of_device_id omap_cb_match[] = {
	{ .compatible = "ti,irq-crossbar-test", },
	{},
};
MODULE_DEVICE_TABLE(of, omap_cb_match);

static int delete_allocation(void *unused)
{
	int i = 0;
	struct irq_desc *desc;

	printk("\n delete_allocation");
	for (i = 0; i < (MAX_IRQS-32); i++)
	{
		if (used_irqs[i])
			continue;

		desc = descs[i];

		if (desc) {
			irq_dispose_mapping(desc->irq_data.irq);
			descs[i] = 0;
		}
	}

	printk("\n successfully disposed all irqs");

	return 0;
}

static int raw_allocation(void *unused)
{
	struct device_node *np;
	int i = 0;
	int irq;

	printk("\n testing raw allocation");

	for (i = 0; i < (MAX_IRQS-32); i++)
	{
		np = platdev[i]->dev.of_node;
		irq = irq_of_parse_and_map(np, 0);
	}

	printk("\n successfully allocated all irqs");

	return 0;
}

static int test_allocation(void *unused)
{
	int irq;
	int i = 0;
	struct irq_desc *desc;
	struct device_node *np;
	int init_virq;

	for (i = 0; i < (MAX_IRQS-32); i++)
	{
		np = platdev[i]->dev.of_node;

		irq = irq_of_parse_and_map(np, 0);

		if (i == 0)
			init_virq = irq;

		printk("\n **********");
		printk("\n virq=%d for %d", irq, i);
		desc = irq_to_desc(irq);

		if (desc && irq && (irq < init_virq)) {
			used_irqs[i] = 1;
			printk("\n irq=%d already used by %d", desc->irq_data.hwirq, i);
		}

		if (!irq) {
			printk("\n irq allocation failed for %d", i);
			continue;
		}

		descs[i] = desc;

		if (desc)
			printk("\n %s is allocated to irq = %d", platdev[i]->name, desc->irq_data.hwirq);
		else
			printk("\n no irq allocated for %s", platdev[i]->name);

	}

	return 0;
}

static int test_allocate_deletion(void)
{
	int i, j = 100;
	struct task_struct *p[2];

	test_allocation(&i);
	delete_allocation(&i);

	while(j--) {
		printk("\n loop %d", j);
		p[0] = kthread_create(test_allocation, &i, "cb_test_thread");
		kthread_bind(p[0], 0);

		p[1] = kthread_create(delete_allocation, &i, "cb_test_thread");
		kthread_bind(p[1], 1);

		wake_up_process(p[0]);
		wake_up_process(p[1]);
	}

	return 0;
}

static int option_get(void *data, u64 *v)
{
	u32 *option = data;

	*v = *option;

	return 0;
}

static int option_set(void *data, u64 v)
{
	test_allocate_deletion();

	return 0;
}

DEFINE_SIMPLE_ATTRIBUTE(omap_cb_test_option_fops, option_get, option_set, "%llu\n");

static int omap_cb_test_probe(struct platform_device *pdev) {

	static int i = 0;

	if (i == 0) {
		d = debugfs_create_dir("cb-test", NULL);
		if (IS_ERR_OR_NULL(d)) {
			pr_err("OMAP cb-Test: Failed to create omap-cb-test directory!%d\n", d);
			return PTR_ERR(d);
		} else {
			printk("\n created directory %d", d);
		}

		debugfs_create_file("cb", S_IRUGO | S_IWUSR, d,
			&omap_cb_test_all, &omap_cb_test_option_fops);

		d = debugfs_create_file("stress", S_IRUGO | S_IWUSR, d,
			&stress, &omap_cb_test_option_fops);

		printk("\n created file %d", d);
	}

	platdev[i++] = pdev;

	return 0;
}

static int omap_cb_test_remove(struct platform_device *pdev) {

	return 0;
}

static struct platform_driver omap_cb_driver = {
	.probe	= omap_cb_test_probe,
	.remove	= omap_cb_test_remove,
	.driver = {
		.name = "irq-cb-test",
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(omap_cb_match),
	},
};

static int omap_cb_init(void)
{
	platform_driver_register(&omap_cb_driver);

	return 0;
}
module_init(omap_cb_init);
