#################################################
# 1. Build testsuite using commands:		#
#################################################

A) cd omap-ddt/

  The following variables are needed for the
  testsuite build system.
  They should be either exported to the environment
  before starting 'make' or passed as parameters to make.

B) export CROSS_COMPILE=arm-none-linux-gnueabi-
C) export KDIR=[PATH-TO-KERNEL]
D) export HOST=arm-none-linux-gnueabi
E) export TESTSUITES=<driver_x>
   * driver_x=The driver for which the testsuite is to be built
   * Use "all" for building the entire testsuite
F) export TESTROOT=<output dir><output dir>
G) make

Note: Please install gengetopt "sudo apt-get install gengetopt"
or remove audio-alsa from TESTSUITES in .config file.

The testsuite will be created in the location specified by <output dir>
If <output dir> is not set, by default the testsuites will be installed
in "build" directory

#################################################
# 2. Target requirements            		#
#################################################

Please refer to the following wiki:

http://omappedia.org/wiki/OMAP_Kernel_driver_tests#Target_Filesystem_setup

#################################################
# 2. Running test scenarios			#
#################################################

1. cd <output dir>/<driver_x>/scripts/
2. Execute a test scenario as follows:

   ./test_runner.sh -S scenario_name

    Test scenarios are listed in scenarios folder:
    ls <output dir>/<driver_x>/scripts/scenarios/

