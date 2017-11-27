#!/bin/sh

answer=$( __get_priority_level )
assert_equals 100 "${answer}"

default="${answer}"

__set_priority_level 20
answer=$( __get_priority_level )
assert_equals 20 "${answer}"

__set_priority_level -1
answer=$( __get_priority_level )
assert_equals 20 "${answer}"

__set_priority_level "${default}"
