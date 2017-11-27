#!/bin/sh

sample_data="A:B:C"
answer=$( add_element )
assert_failure $?
assert_empty "${answer}"

answer=$( add_element --data "${sample_data}" --new-data 'D' --separator ':' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'D:A:B:C' "${answer}"

answer=$( add_element --data "${sample_data}" --id 2 --separator ':' --new-data 'D' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'A:D:B:C' "${answer}"

answer=$( add_element --data "${sample_data}" --id 0 --separator ':' --new-data 'D' )
assert_failure $?
assert_not_empty "${answer}"
assert_equals "${sample_data}" "${answer}"

answer=$( add_element --data "${sample_data}" --id 6 --separator ':' --new-data 'D' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'A:B:C:::D' "${answer}"
