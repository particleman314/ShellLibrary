#!/bin/sh

sample_data="0110010101001010"
answer=$( get_bit_setting --data "${sample_data}" --id 1 )
assert_not_empty "${answer}"
assert_false "${answer}"

answer1=$( get_bit_setting --data "${sample_data}" --id 3 )
assert_success $?
assert_true "${answer1}"

answer=$( get_bit_setting --data "${sample_data}" )
assert_failure $?

answer=$( get_bit_setting --id 4 )
assert_failure $?

answer=$( get_bit_setting --data "${sample_data}" --id '-1' )
assert_failure $?

answer=$( get_bit_setting --id 18 --data "${sample_data}" )
assert_failure $?
