#!/usr/bin/env bash

f1=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${f1}"
assert_is_file "${f1}"

f2=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${f2}"
assert_is_file "${f2}"
assert_equals "${f1}" "${f2}"

append_output
assert_success $?

before_fs=$( __calculate_filesize "${f1}" )
append_output --data "Hello World"
assert_success $?
after_fs=$( __calculate_filesize "${f1}" )
assert_not_equals "${before_fs}" "${after_fs}"
detail "<${before_fs}> -- <${after_fs}>"

result=$( append_output --data "Hello World" --channel STDOUT )
assert_success $?
assert_equals "Hello World" "${result}"
detail "${result}"

before_fs=$( __calculate_filesize "${f1}" )
result=$( append_output --data 'Hello World 2.0' --raw )
assert_success $?
after_fs=$( __calculate_filesize "${f1}" )
assert_not_equals "${before_fs}" "${after_fs}"

append_output --data "Hello World" --channel 'ABC' --marker 'HELLO'
assert_success $?
result=$( \cat "${f1}" )
assert_not_equals "Hello World" "${result}"
detail "${result}"

inputs=$( \ls -1 )
append_output --data "${inputs}" --channel 'ABC' --marker 'LISTING'
assert_success $?
result=$( \cat "${f1}" )
assert_not_equals "Hello World" "${result}"
detail "${result}"

#assert_greater_equal $( get_number_output_files ) 1

if [ -n "${SLCF_DETAIL}" ] && [ "${SLCF_DETAIL}" -ne "${NO}" ]
then
  printf "%s\n" "========"
  \cat "${f1}"
fi

__cleanup_filemgr
