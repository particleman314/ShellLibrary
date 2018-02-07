#!/usr/bin/env bash

answer=$( __determine_nic_id )
RC=$?
assert_failure "${RC}"
assert_empty "${answer}"

###
### This test is specific to the machine for which it is running
###
answer=$( __determine_nic_id "virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500" )
RC=$?
assert_success "${RC}"
assert_not_empty "${answer}"
assert_equals 'virbr0' "${answer}"
detail "${answer}"
