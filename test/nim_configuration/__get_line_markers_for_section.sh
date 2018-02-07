#!/usr/bin/env bash

assert_not_empty "${TEST_CONFIG_BASIC}"

section='/test_config_basic'

answer=$( __get_line_markers_for_section "${TEST_CONFIG_BASIC}" "${section}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 1 $( get_element --data "${answer}" --id 1 --separator ':' )
assert_equals 4 $( get_element --data "${answer}" --id 2 --separator ':' )

section='/no_known_section'

answer=$( __get_line_markers_for_section "${TEST_CONFIG_BASIC}" "${section}" )
assert_failure $?
assert_not_empty "${answer}"
assert_equals 0 $( get_element --data "${answer}" --id 1 --separator ':' )
assert_equals 0 $( get_element --data "${answer}" --id 2 --separator ':' )

assert_not_empty "${TEST_CONFIG_MEDIUM}"

section='/hub/tunnel/certificates/1'

answer=$( __get_line_markers_for_section "${TEST_CONFIG_MEDIUM}" "${section}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 11 $( get_element --data "${answer}" --id 1 --separator ':' )
assert_equals 13 $( get_element --data "${answer}" --id 2 --separator ':' )

assert_not_empty "${TEST_CONFIG_DEEP}"

section='/disk/alarm/fixed/C:\\/error'

answer=$( __get_line_markers_for_section "${TEST_CONFIG_DEEP}" "${section}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 475 $( get_element --data "${answer}" --id 1 --separator ':' )
assert_equals 479 $( get_element --data "${answer}" --id 2 --separator ':' )
