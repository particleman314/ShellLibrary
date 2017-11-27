#!/bin/sh

assert_not_empty "${TEST_JSON}"

__disable_json_failure 2
answer=$( json_validate )
assert_failure $?
assert_equals "${NO}" "${answer}" 

force_skip
answer=$( json_validate --jsonfile "${TEST_JSON}" )
assert_success $?
assert_equals "${YES}" "${answer}"
clear_force_skip

__enable_json_failure
