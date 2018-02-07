#!/usr/bin/env bash

###
### Exercise TeamCity at CA
###

answer=$( __get_rest_api_address 'TEAMCITY' )
RC=$?
assert_failure "${RC}"

__set_rest_api_address 'TEAMCITY' 'http://teamcity'
assert_success $?

answer=$( __get_rest_api_address 'TEAMCITY' )
RC=$?
assert_success "${RC}"
assert_equals "${answer}" 'http://teamcity'
