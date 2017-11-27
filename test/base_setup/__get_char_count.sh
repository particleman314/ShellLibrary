#!/bin/sh

sample=''

answer=$( __get_char_count "${sample}" )
assert_failure $?
assert_equals 0 "${answer}"

sample='abc'

answer1=$( __get_char_count --non-file "${sample}" )
assert_success $?
assert_equals 3 "${answer1}"

sample="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/.sample_char_count_file"
schedule_for_demolition "${sample}"

printf "%s\n" 'abcdefghijklmnopqrstuvwxyz' > "${sample}"
answer2=$( __get_char_count "${sample}" )
assert_success $?
assert_equals 27 "${answer2}"  # need to include the newline char...
