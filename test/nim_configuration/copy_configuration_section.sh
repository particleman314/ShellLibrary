#!/usr/bin/env bash

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_SIMPLE}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/test_config_basic'
new_section='/abc'

copy_configuration_section
assert_failure $?

copy_configuration_section --cfgfile "${copy_cfg}"
assert_failure $?

copy_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${new_section}"assert_failure $?

copy_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${new_section}" --new-cfgsection "${new_section}"
assert_failure $?

copy_configuration_section --cfgfile "what_file" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_failure $?

copy_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${new_section}" --key 'key1' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'Hello' "${answer}"

new_section='/test_config_basic/abc/123'

copy_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_success $?
