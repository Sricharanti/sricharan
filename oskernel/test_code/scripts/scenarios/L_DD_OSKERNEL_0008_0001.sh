#!/bin/bash
############################################################################
# Scenario: L_DD_OSKERNEL_0008_0001
# Author  : Mariia Nagul
# Date    : Feb 3, 2012
# Testing : VFP/NEON floating point, vector math
###############################################################################

# Begin L_DD_OSKERNEL_0008_0001

  vfp=$(cat $KDIR/.config | grep VFP | sed "s/CONFIG_VFP[a-zA-Z0-9]*=//")
  neon=$(cat $KDIR/.config | grep NEON | sed "s/CONFIG_NEON[a-zA-Z0-9]*=//")
  for v in $vfp; do [ $v == "y" ] && t=1 && continue || t=0 && break; done
 [  $t == 1 -a $neon == y ] && echo "VFP/NEON is supported Test PASS"  || echo "VFP/NEON support is not configured Test FAIL"

# End L_DD_OSKERNEL_0008_0001
