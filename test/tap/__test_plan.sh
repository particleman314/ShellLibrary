#!/usr/bin/env bash

answer=$( has_plan )
assert_success $?
assert_equals "${NO}" "${answer}"

answer=$( __test_plan )
assert_failure $?

answer=$( __test_plan 0 )
assert_failure $?
assert_equals 'Must run at least one (1) test!' "${answer}"

answer=$( __test_plan 10 )
assert_success $?
assert_equals '1..10' "${answer}"
assert_true $( has_plan )

answer=$( __test_plan 42 )
assert_success $?
assert_equals 'Cannot set the plan more than once!' "${answer}"

__reset_plan
