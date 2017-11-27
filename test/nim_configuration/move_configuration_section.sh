#!/bin/sh

assert_not_empty "${TEST_CONFIG_MEDIUM}"

copy_cfg="${TEST_CONFIG_MEDIUM}.sample"
cp -f "${TEST_CONFIG_MEDIUM}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/hub/tunnel/certificates'
new_section='/abc'

move_configuration_section
assert_failure $?

move_configuration_section --cfgfile "${copy_cfg}"
assert_failure $?

move_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${new_section}"
assert_failure $?

move_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${new_section}/1" --key 'cert' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'test.pem' "${answer}"
