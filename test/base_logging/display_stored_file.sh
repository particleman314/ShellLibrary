#!/usr/bin/env bash

f1=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${f1}"
#assert_is_file "${f1}"

append_output --data "Hello World"
assert_success $?

display_stored_file
assert_failure $?

display_stored_file --channel 'ABC'
assert_success $?

display_stored_file --file "${f1}"
assert_success $?

__cleanup_filemgr
