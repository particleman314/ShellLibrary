#!/usr/bin/env bash

. "${SLCF_CURRENT_TEST_LOCATION}/__setup_configuration.sh"
assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='test_config_basic'
key='key1'

remove_configuration_key 
assert_failure $?

remove_configuration_key --cfgfile "${copy_cfg}"
assert_failure $?

remove_configuration_key --cfgsection "${section}"
assert_failure $?

remove_configuration_key --key "${key}"
assert_failure $?

remove_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}"
assert_failure $?

remove_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'blah'
assert_failure $?

remove_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}"
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" )
assert_empty "${answer}"
assert_is_file "${copy_cfg}"

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'key2' )
assert_success $?
assert_not_empty "${answer}"

copy_cfg="${TEST_CONFIG_MEDIUM}.sample"
cp -f "${TEST_CONFIG_MEDIUM}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/hub/tunnel/certificates/1'
key='cert'

remove_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}"
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" )
assert_failure $?
assert_empty "${answer}"
