#!/bin/sh

assert_not_empty "${TEST_JSON}"

__disable_json_failure 2
json_check_file
assert_failure $?

json_check_file --jsonfile "${TEST_JSON}"
assert_success $?

json_check_file --errorcode 10
assert $? 10

__enable_json_failure
