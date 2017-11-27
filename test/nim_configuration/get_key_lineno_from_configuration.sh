#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_SIMPLE}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

section='test_config_basic'
key='key1'

answer=$( get_key_lineno_from_configuration )
assert_failure $?

answer=$( get_key_lineno_from_configuration --cfgsection "${section}" )
assert_failure $?

answer=$( get_key_lineno_from_configuration --key "${key}" )
assert_failure $?

answer=$( get_key_lineno_from_configuration --cfgsection "${section}" --key "${key}" )
assert_failure $?

answer=$( get_key_lineno_from_configuration --cfgfile 'blah' --cfgsection "${section}" --key "${key}" )
assert_failure $?

answer=$( get_key_lineno_from_configuration --cfgfile "${TEST_CONFIG_SIMPLE}" --key "${key}" )
assert_failure $?

answer=$( get_key_lineno_from_configuration --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 2 "${answer}"

section='/hub/tunnel/certificates/1'
key='cert'
answer=$( get_key_lineno_from_configuration --cfgfile "${TEST_CONFIG_MEDIUM}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 12 "${answer}"
