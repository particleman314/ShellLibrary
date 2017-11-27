#!/bin/sh

answer=$( __get_empty_line )
assert_success $?
assert_not_empty "${answer}"
assert_greater "${#answer}" 0
