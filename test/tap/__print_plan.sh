#!/bin/sh

answer=$( has_plan )
assert_success $?
assert_equals 0 "${answer}"

__no_plan
answer=$( has_plan )
assert_success $?
assert_equals 1 "${answer}"

answer=$( __print_plan )
assert_success $?
assert_not_empty "${answer}"
assert_equals '1..?' "${answer}"

answer=$( __print_plan 10 )
assert_success $?
assert_not_empty "${answer}"
assert_equals '1..10' "${answer}"

answer=$( __print_plan 42 TODO )
assert_success $?
assert_not_empty "${answer}"
assert_equals '1..42 # TODO' "${answer}"

__reset_plan
