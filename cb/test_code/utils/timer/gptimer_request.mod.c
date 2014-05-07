#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

__visible struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
	.arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0xbed1a80b, __VMLINUX_SYMBOL_STR(module_layout) },
	{ 0xba23f89d, __VMLINUX_SYMBOL_STR(simple_attr_release) },
	{ 0xa099c5d6, __VMLINUX_SYMBOL_STR(simple_attr_write) },
	{ 0xb80f992b, __VMLINUX_SYMBOL_STR(simple_attr_read) },
	{ 0x75b12ee2, __VMLINUX_SYMBOL_STR(generic_file_llseek) },
	{ 0x2e5810c6, __VMLINUX_SYMBOL_STR(__aeabi_unwind_cpp_pr1) },
	{ 0x14f4cfc6, __VMLINUX_SYMBOL_STR(__platform_driver_register) },
	{ 0x24b31a99, __VMLINUX_SYMBOL_STR(debugfs_create_file) },
	{ 0x578443ac, __VMLINUX_SYMBOL_STR(debugfs_create_dir) },
	{ 0x2e9738ba, __VMLINUX_SYMBOL_STR(wake_up_process) },
	{ 0xe9c1ad58, __VMLINUX_SYMBOL_STR(kthread_bind) },
	{ 0x8a0cc729, __VMLINUX_SYMBOL_STR(kthread_create_on_node) },
	{ 0x1cd0c4d5, __VMLINUX_SYMBOL_STR(irq_to_desc) },
	{ 0x595a07df, __VMLINUX_SYMBOL_STR(irq_of_parse_and_map) },
	{ 0x2c7db649, __VMLINUX_SYMBOL_STR(irq_dispose_mapping) },
	{ 0x8ea80fca, __VMLINUX_SYMBOL_STR(printk) },
	{ 0xf9896588, __VMLINUX_SYMBOL_STR(simple_attr_open) },
	{ 0xefd6cf06, __VMLINUX_SYMBOL_STR(__aeabi_unwind_cpp_pr0) },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("of:N*T*Cti,irq-crossbar-test*");

MODULE_INFO(srcversion, "94576D1F4907238E83C7828");
