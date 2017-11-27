#!/bin/sh

display_text='Hello World'

assert_not_empty "${COLUMNS}"
printf "%d\n" "${COLUMNS}"

result=$( center_text )
assert_failure $?

result1=$( center_text --text "${display_text}" )
assert_success $?
assert_not_empty "${result1}"
printf "%s\n" "${result1}"

result2=$( center_text --text "${display_text}" -- width 0 )
assert_success $?
assert_not_empty "${result2}"
assert_equals "${result1}" "${result2}"
printf "%s\n" "${result2}"

result=$( center_text --text "${display_text}" --width 1 )
assert_success $?
assert_not_empty "${result}"
assert_equals "${display_text}" "${result}"
printf "%s\n" "${result}"

width=$(( ${#display_text} + 15 ))
result=$( center_text --text "${display_text}" --width ${width} )
assert_success $?
assert_not_empty "${result}"
printf "%s\n" "${result}"
