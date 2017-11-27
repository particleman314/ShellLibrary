#!/bin/sh

answer=$( has_plan )
assert_success $?
assert_equals 0 "${answer}"

__no_plan
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

__reset_plan
answer=$( has_plan )
assert_success $?
assert_equals 0 "${answer}"

__skip_all
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

__reset_plan

__test_plan 10
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

__reset_plan

__test_plan 10 'Sample of the top of TAP output'
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

__reset_plan
