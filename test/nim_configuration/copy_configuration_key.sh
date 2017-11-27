#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_SIMPLE}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/test_config_basic'
known_key='key1'
new_key='key1_copy'

copy_configuration_key --cfgfile "${copy_cfg}"
assert_failure $?

copy_configuration_key --cfgsection "${section}" 
assert_failure $?

copy_configuration_key --new-cfgsection "${section}"
assert_failure $?

copy_configuration_key --key "${known_key}"
assert_failure $?

copy_configuration_key --newkey "${new_key}" 
assert_failure $?

copy_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${known_key}" --newkey "${new_key}"
assert_success $?
assert_equals 'Hello' $( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${new_key}" )

copy_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection '/another/test/location' --key 'key2' --newkey 'key2_copy'
assert_success $?
assert_equals 'World' $( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection '/another/test/location' --key 'key2_copy' )
