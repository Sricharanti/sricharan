#!/bin/bash -x

    adb reboot
    echo "Waiting for $TARGET" && sleep 10
    echo "Waiting for device" && adb 'wait-for-device'
    sleep 10
    adb root && sleep 3
    # To verify system started up properly checking dmesg
    adb shell "dmesg"
    [ $? -ne 0 ] && echo "test FAIL" && exit 1 || echo "Test PASS" && exit 0

