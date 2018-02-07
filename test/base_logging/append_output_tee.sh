#!/usr/bin/env bash

f1=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${f1}"
#assert_is_file "${f1}"

append_output_tee
assert_success $?

append_output_tee --data 'Mad World'
assert_success $?

before_fs=$( __calculate_filesize "${f1}" )
append_output_tee --data 'Mad World 2.0' --channel ABC
assert_success $?
after_fs=$( __calculate_filesize "${f1}" )
detail "Before : ${before_fs} -- After : ${after_fs}"
assert_not_equals "${before_fs}" "${after_fs}"

append_output_tee --data 'Split Output' --channel ABC --channel 'UZV'
assert_success $?
assert_greater_equal $( get_number_output_files ) 2

result=$( append_output_tee --data 'Bad data' --channel ERROR )
assert_success $?
assert_not_empty "${result}"
assert_match 'ERROR' "${result}"
#assert_greater_equal $( get_number_output_files ) 3

if [ -n "${SLCF_DETAIL}" ] && [ "${SLCF_DETAIL}" -ne "${NO}" ]
then
  printf "%s\n" "======"
  cat $( find_output_file --channel ERROR )
fi

__cleanup_filemgr
