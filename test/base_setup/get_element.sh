#!/bin/sh

sample_data="A:B:C:D-E;F"
answer=$( get_element --data "${sample_data}" --id 1 --separator ':' )
assert_not_empty "${answer}"
assert_equals 'A' "${answer}"

answer=$( get_element --data "${sample_data}" --id 3 )
assert_success $?
assert_empty "${answer1}"

answer=$( get_element --data "${sample_data}" --id 1 --separator 'L' )
assert_not_empty "${answer}"
assert_equals "${sample_data}" "${answer}"

answer=$( get_element --data "${sample_data}" --id '-1' --separator ':' )
assert_failure $?

sample_data=':5'
answer=$( get_element --data "${sample_data}" --id 1 --separator ':' )
assert_empty "${answer}"

answer=$( get_element --data "${sample_data}" --id 2 --separator ':' )
assert_equals 5 "${answer}"

sample_data="A::B::D-E"
answer=$( get_element --data "${sample_data}" --id 2 --separator '::' )
assert_equals 'B' "${answer}"

answer=$( get_element --data "${sample_data}" --id 4 --separator '::' )
assert_empty "${answer}"

answer=$( get_element )
assert_failure $?

answer=$( get_element --id 5 )
assert_failure $?

answer=$( get_element --data "${sample_data}" )
assert_failure $?

answer=$( get_element --data "${sample_data}" --id 3 --separator '::' )
assert_success $?
assert_equals 'D-E' "${answer}"
