#!/bin/sh

reserve_answer=$( get_parameter_separator )
assert_success $?
assert_not_empty "${reserve_answer}"
assert_equals ':' "${reserve_answer}"

set_parameter_separator '|'

answer=$( get_parameter_separator )
assert_success $?
assert_not_empty "${answer}"
assert_equals '|' "${answer}"

set_parameter_separator "${reserve_answer}"
