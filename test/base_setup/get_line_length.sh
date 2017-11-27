#!/bin/sh

line=''
answer=$( get_line_length "${line}" )
assert_success $?
assert_equals 0 "${answer}"

line='ABC'
answer1=$( get_line_length "${line}" )
assert_success $?
assert_equals 3 "${answer1}"

line='1234567890'
answer2=$( get_line_length "${line}" )
assert_success $?
assert_equals 10 "${answer2}"
