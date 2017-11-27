#!/bin/sh

answer=$( has_plan )
assert_success $?
assert_equals 0 "${answer}"

__no_plan
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

answer=$( __no_plan )
assert_success $?
assert_not_empty "${answer}"

__reset_plan
