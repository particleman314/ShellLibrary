#!/usr/bin/env bash

sample=''

answer=$( __get_line_count "${sample}" )
assert_failure $?
assert_equals 0 "${answer}"

sample='abc'

answer1=$( __get_line_count --non-file "${sample}" )
assert_success $?
assert_equals 1 "${answer1}"

sample="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/.sample_line_count_file"
schedule_for_demolition "${sample}"
counter=10

\which 'seq' >/dev/null 2>&1
if [ $? -eq 0 ]
then
  for loop in $( \seq 1 ${counter} )
  do
    printf "%s\n" 'abcdefghijklmnopqrstuvwxyz' >> "${sample}"
  done

  answer2=$( __get_line_count "${sample}" )
  assert_success $?
  assert_equals "${counter}" "${answer2}"
else
  detail "Unable to complete testing since 'seq' executable not found"
fi
