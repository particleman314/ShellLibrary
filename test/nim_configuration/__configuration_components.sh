#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"

section='/test_config_basic'
answer=$( count_items --data "$( __configuration_components "${section}" )" )
assert_equals 1 "${answer}"

section='/hub/tunnel/certificates'
answer=$( count_items --data "$( __configuration_components "${section}" )" )
assert_equals 3 "${answer}"

section='/cpu/alarm/error/threshold/message'
answer=$( count_items --data "$( __configuration_components "${section}" )" )
assert_equals 5 "${answer}"

section=
answer=$( count_items --data "$( __configuration_components "${section}" )" )
assert_equals 0 "${answer}"
