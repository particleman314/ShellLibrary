#!/usr/bin/env bash

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_SIMPLE}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

old_section='/test_config_basic'
new_section='/test_config_nonbasic'
key='key1'

move_configuration_key --cfgfile "${copy_cfg}"
assert_failure $?

move_configuration_key --cfgsection "${old_section}" 
assert_failure $?

move_configuration_key --new-cfgsection "${new_section}"
assert_failure $?

move_configuration_key --key "${key}"
assert_failure $?

move_configuration_key --newkey "${key}" 
assert_failure $?

move_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${old_section}" --new-cfgsection "${new_section}" --key "${key}" --newkey "${key}"
assert_success $?
assert_equals 'Hello' $( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${new_section}" --key "${key}" )

move_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${old_section}" --new-cfgsection '/another/test/location' --key 'key2' --newkey 'key2_copy'
assert_success $?
assert_equals 'World' $( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection '/another/test/location' --key 'key2_copy' )
