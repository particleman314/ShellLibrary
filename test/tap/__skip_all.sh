#!/bin/sh

answer=$( has_plan )
assert_success $?
assert_equals "${NO}" "${answer}"

__no_plan
answer=$( has_plan )
assert_success $?
assert_equals "${YES}" "${answer}"

__reset_plan

answer=$( __skip_all )
assert_success $?
assert_not_empty "${answer}"

__reset_plan
