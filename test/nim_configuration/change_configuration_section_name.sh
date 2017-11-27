#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='test_config_basic'
new_section='different_config'

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" )
assert_success $?
assert_true "${answer}"

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${new_section}" )
assert_success $?
assert_false "${answer}"

new_section="${section}"
change_configuration_section_name --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_success $?

new_section='different_config'
change_configuration_section_name --cfgfile "${copy_cfg}" --cfgsection "${section}" --new-cfgsection "${new_section}"
assert_success $?

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${new_section}" )
assert_success $?
assert_true "${answer}"

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" )
assert_success $?
assert_false "${answer}"
