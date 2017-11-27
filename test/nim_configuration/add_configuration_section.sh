#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/test_config_basic'
key='logsize'

add_configuration_section --cfgsection "${section}/new_section"
assert_failure $?

add_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}/new_section_old"
assert_success $?

add_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}/new_section/hub/tunnel/certificate"
assert_success $?

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}/new_section/hub" )
assert_true "${answer}"

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}/new_section" --key "${key}" --value 2000
assert_success $?

answer=$( get_key_from_configuration --cfgfile "${copy_cfg}" --cfgsection "${section}/new_section" --key "${key}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals 2000 "${answer}"
