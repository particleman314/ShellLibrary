#!/usr/bin/env bash

f1=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${f1}"
assert_is_file "${f1}"

answer=$( get_number_output_files )
assert_success $?

detail "Number Files : ${answer}"
assert_greater_equals "${answer}" 1

__cleanup_filemgr
