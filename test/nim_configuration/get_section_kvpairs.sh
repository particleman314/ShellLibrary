#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

section='/test_config_basic'

answer=$( get_section_kvpairs --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection "${section}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 2 $( count_items --data "${answer}" --separator ':' )

answer=$( get_section_kvpairs --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection '/does_not_exist' )
assert_failure $?

answer=$( get_section_kvpairs --cfgfile "${TEST_CONFIG_DEEP}" --cfgsection '/setup' )
assert_success $?
assert_equals 10 $( count_items --data "${answer}" --separator ':' )

answer=$( get_section_kvpairs --cfgfile "${TEST_CONFIG_DEEP}" --cfgsection '/cpu/alarm/error' )
assert_success $?
assert_equals 4 $( count_items --data "${answer}" --separator ':' )
