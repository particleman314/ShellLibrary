#!/usr/bin/env bash

sample=''

answer=$( __get_word_count "${sample}" )
assert_failure $?
assert_equals 0 "${answer}"

sample='abc def'

answer1=$( __get_word_count --non-file "${sample}" )
assert_success $?
assert_equals 2 "${answer1}"

sample="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/.sample_word_count_file"
schedule_for_demolition "${sample}"
printf "%s\n" 'abc def ghi jkl mno pqr stu vwx yz' > "${sample}"

answer2=$( __get_word_count "${sample}" )
assert_success $?
assert_equals 9 "${answer2}"

