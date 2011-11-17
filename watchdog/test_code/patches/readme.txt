Steps to test Watchdog module with kernel patch:
---------------------------------------------------------

1. Apply the patch "0001-Fix-to-get-watchdog-IOCTL-test-working.patch" located in path /omap-ddt/watchdog/patches/L27x to your kernel.
This patch does the following:
a. To allow any user to open the watchdog device and access it IOCTLs we have disabled watchdog petting option. In normal circumstances no one is allowed to access the watchdog other than Kernel. So this is required to open up an interface to test watchdog functionalities
b. The spin locks in IOCTL code are replaced by mutex since the pm runtime functions are called from within the locks which tend to sleep and kernel does not like it.

2. Rebuild the kernel and omap-ddt watchdog test

3. Run the watchdog tests specified in path /omap-ddt/watchdog/scripts/scenarios

4. Make sure to revert the patch before testing other modules since this patch does not have watchdog petting option which might result in system not rebooting on a hang

