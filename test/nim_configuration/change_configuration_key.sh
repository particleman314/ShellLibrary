#!/usr/bin/env bash

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='test_config_basic'
key='logsize'

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'logsize' --value 3000
assert_success $?

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'loglevel'
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" )                                     
assert_success $?
assert_equals 3000 "${answer}"

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'loglevel' )                                     
assert_success $?
assert_empty "${answer}"

change_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" --value 1000

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 1000 "${answer}"
