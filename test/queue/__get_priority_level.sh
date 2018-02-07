#!/usr/bin/env bash

answer=$( __get_priority_level )
assert_equals "${DEFAULT_PRIORITY_LEVEL}" "${answer}"

detail "Current Priority Level = <${answer}>  ${DEFAULT_PRIORITY_LEVEL}"
default="${answer}"

__set_priority_level 20
answer=$( __get_priority_level )
assert_equals 20 "${answer}"

__set_priority_level -1
answer=$( __get_priority_level )
assert_equals 20 "${answer}"

__set_priority_level "${default}"
