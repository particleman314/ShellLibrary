#!/bin/sh

assert_not_empty "${TEST_CONFIG_BASIC}"
assert_not_empty "${TEST_CONFIG_MEDIUM}"
assert_not_empty "${TEST_CONFIG_DEEP}"

section='/test_config_basic'

answer=$( has_configuration_section --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection "${section}" )
assert_success $?
assert_true "${answer}"

answer=$( has_configuration_section --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection '/blah' )
assert_success $?
assert_false "${answer}"

answer=$( has_configuration_section --cfgfile "${TEST_CONFIG_MEDIUM}" --cfgsection '/hub/tunnel/certificates' )
assert_success $?
assert_true "${answer}"
