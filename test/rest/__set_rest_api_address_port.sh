#!/bin/sh

###
### Exercise TeamCity at CA
###

answer=$( __get_rest_api_address_port 'TEAMCITY' )
RC=$?
assert_failure "${RC}"

__set_rest_api_address_port 'TEAMCITY' '8111'
assert_success $?

answer=$( __get_rest_api_address_port 'TEAMCITY' )
RC=$?
assert_success "${RC}"
assert_equals "${answer}" '8111'