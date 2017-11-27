#!/bin/sh

answer=$( get_verbosity_info )
assert_success $?
assert_empty "${answer}"

answer=$( get_verbosity_info --verbose )
assert_success $?
assert_not_empty "${answer}"

level1verbosity="${answer}"

answer=$( get_verbosity_info --verbose --verbose )
assert_success $?
assert_not_empty "${answer}"
assert_not_equals "${level1verbosity}" "${answer}"

detail "Level 1 verbosity   : ${level1verbosity}"
detail "Level > 1 verbosity : ${answer}"
