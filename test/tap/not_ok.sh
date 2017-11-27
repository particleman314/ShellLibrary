#!/bin/sh

#answer=$( not_ok "${PASS}" )
#assert_failure $?
#detail "${answer}"
#assert_equals 'not ok' "${answer}"

#answer=$( not_ok "${FAIL}" )
#assert_success $?
#assert_equals 'ok' "${answer}"

#answer=$( not_ok "${FAIL}" MyFirstTest )
#assert_success $?
#assert_equals 'ok' "${answer}"

TAP_VERBOSE="${YES}"
answer=$( not_ok "${FAIL}" MyFirstTest )
assert_success $?
assert_equals "MyFirstTest .. ok 1 - 0" "${answer}"
TAP_VERBOSE="${NO}"
