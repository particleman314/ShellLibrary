#!/bin/sh

answer=$( repeat )
assert_failure $?

answer=$( repeat --repeat-char '|' )
assert_failure $?

answer=$( repeat --repeat-char '+' --number-times 0 )
assert_failure $?

answer=$( repeat --repeat-char '+' --number-times 10 )
assert_success $?
assert_equals '++++++++++' "${answer}"
