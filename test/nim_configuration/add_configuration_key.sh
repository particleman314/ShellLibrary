#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='test_config_basic'
key='logsize'

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" ) 
assert_failure $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'key1' )
assert_success $?
assert_equals 'Hello' "${answer}"

add_configuration_key
assert_failure $?

add_configuration_key --cfgfile "${copy_cfg}"
assert_failure $?

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" 
assert_failure $?

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'logsize' --value 3000
assert_success $?

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'loglevel'
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'logsize' )                                     
assert_success $?
assert_equals 3000 "${answer}"

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'loglevel' )
assert_success $?
assert_empty "${answer}"
