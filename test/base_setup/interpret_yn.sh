#!/bin/sh

input=1
answer1=$( interpret_yn "${input}" )
assert_success $?
assert_equals 'YES' "${answer1}"

input=0
answer2=$( interpret_yn "${input}" )
assert_success $?
assert_equals 'NO' "${answer2}"
