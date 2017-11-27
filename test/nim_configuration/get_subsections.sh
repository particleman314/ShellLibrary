#!/bin/sh

#assert_not_empty "${TEST_CONFIG_BASIC}"
#assert_not_empty "${TEST_CONFIG_DEEP}"

#section='/test_config_basic'

#answer=$( get_subsections --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection '/does_not_exist' )
#assert_failure $?

#answer=$( get_subsections --cfgfile "${TEST_CONFIG_BASIC}" )
#assert_failure $?

#answer=$( get_subsections --cfgsection "${section}" )
#assert_failure $?

#answer=$( get_subsections --cfgfile "${TEST_CONFIG_BASIC}" --cfgsection "${section}" )
#assert_success $?
#assert_empty "${answer}"

#answer=$( get_subsections --cfgfile "${TEST_CONFIG_SIMPLE}" --cfgsection '/controller' )
#assert_success $?
#assert_not_empty "${answer}"
#assert_equals 5 $( count_items --data "${answer}" )

#answer=$( get_subsections --cfgfile "${TEST_CONFIG_SIMPLE}" --cfgsection '/controller/sublevel/subsublevel' )
#assert_success $?
#assert_not_empty "${answer}"
#assert_equals 3 $( count_items --data "${answer}" )

#section='/messages'
#answer=$( get_subsections --cfgfile "${TEST_CONFIG_DEEP}" --cfgsection "${section}" )
#assert_success $?
#assert_not_empty "${answer}"
#assert_equals 52 $( count_items --data "${answer}" )

#section='/hub'
#answer=$( get_subsections --cfgfile "${TEST_CONFIG_MEDIUM}" --cfgsection "${section}" )
#assert_success $?
#assert_not_empty "${answer}"
#assert_equals 4 $( count_items --data "${answer}" )
#assert_match '/hub/tunnel/certificates' "${answer}"
