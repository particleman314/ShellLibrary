#!/bin/sh

. "${SLCF_CURRENT_TEST_LOCATION}/__setup_configuration.sh"
assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_DEEP}"

copy_cfg="${TEST_CONFIG_BASIC}.sample"
cp -f "${TEST_CONFIG_BASIC}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/test_config_basic'
key='logsize'

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key "${key}" --value 3000
assert_success $?

add_configuration_key --cfgfile "${copy_cfg}" --cfgsection "${section}" --key 'loglevel'
assert_success $?

remove_configuration_section --cfgsection "${section}"
assert_failure $?

remove_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}"
assert_success $?

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" )
assert_not_empty "${answer}"
assert_false "${answer}"

copy_cfg="${TEST_CONFIG_DEEP}.sample"
cp -f "${TEST_CONFIG_DEEP}" "${copy_cfg}"
schedule_for_demolition "${copy_cfg}"

section='/disk'

remove_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}"
assert_success $?

answer=$( has_configuration_section --cfgfile "${copy_cfg}" --cfgsection "${section}" )
assert_not_empty "${answer}"
assert_false "${answer}"
