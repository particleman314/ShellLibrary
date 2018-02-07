#!/usr/bin/env bash

answer=$( plan )
assert_failure $?

answer=$( plan 10 )
assert_success $?
assert_equals '1..10' "${answer}"

answer=$( plan 42 )
assert_success $?

__reset_plan

answer=$( plan no_plan )
assert_success $?

__reset_plan

answer=$( plan skip_all )
assert_success $?
assert_equals '1..0' "${answer}"

__reset_plan
