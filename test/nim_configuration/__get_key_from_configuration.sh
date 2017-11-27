#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_SIMPLE}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

section='test_config_basic'
key='key1'

answer=$( __get_key_from_configuration )
assert_failure $?

answer=$( __get_key_from_configuration --cfgsection "${section}" )
assert_failure $?

answer=$( __get_key_from_configuration --key "${key}" )
assert_failure $?

answer=$( __get_key_from_configuration --cfgsection "${section}" --key "${key}" )
assert_failure $?

answer=$( __get_key_from_configuration --cfgfile 'blah' --cfgsection "${section}" --key "${key}" )
assert_failure $?

answer=$( __get_key_from_configuration --cfgfile "${TEST_CONFIG_SIMPLE}" --key "${key}" )
assert_failure $?

answer=$( __get_key_from_configuration --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 2 $( get_element --data "${answer}" --id 2 --separator ':' )
assert_equals 'Hello' $( get_element --data "${answer}" --id 1 --separator ':' )

section='/hub/tunnel/certificates'
key='cert'
answer=$( __get_key_from_configuration --cfgfile "${TEST_CONFIG_MEDIUM}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'test.pem' $( get_element --data "${answer}" --id 1 --separator ':' )

section='/disk/alarm/connections'
key='level'
answer=$( __get_key_from_configuration --cfgfile "${TEST_CONFIG_DEEP}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'minor' $( get_element --data "${answer}" --id 1 --separator ':' )
