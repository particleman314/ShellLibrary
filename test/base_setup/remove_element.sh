#!/bin/sh

sample_data="A:B:C"
answer=$( remove_element )
assert_failure $?
assert_empty "${answer}"

answer=$( remove_element --data "${sample_data}" --separator ':' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'B:C' "${answer}"

answer=$( remove_element --data "${sample_data}" --id 2 --separator ':' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'A:C' "${answer}"

answer=$( remove_element --data "${sample_data}" --id 6 --separator ':' --new-data 'D' )
assert_success $?
assert_not_empty "${answer}"
assert_equals "${sample_data}" "${answer}"
