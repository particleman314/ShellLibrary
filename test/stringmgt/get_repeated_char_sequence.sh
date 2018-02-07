#!/usr/bin/env bash

charseq='+'

assert_greater_equal "${COLUMNS:-0}" 0

result=$( get_repeated_char_sequence )
assert_not_empty "${result}"
detail "${result}"

result2=$( get_repeated_char_sequence --repeat-char "${charseq}" )
assert_not_empty "${result2}"
assert_not_equals "${result}" "${result2}"
detail "${result2}"

result=$( get_repeated_char_sequence --count 40 )
assert_not_empty "${result}"
assert_not_equals "${result}" "${result2}"
detail "${result}"

result2=$( get_repeated_char_sequence --count 0 )
assert_failure $? 
assert_empty "${result2}"
