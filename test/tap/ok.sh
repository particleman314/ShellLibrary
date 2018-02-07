#!/usr/bin/env bash

answer=$( ok "${PASS}" )
assert_success $?
assert_equals 'ok' "${answer}"

answer=$( ok "${FAIL}" )
assert_failure $?
assert_equals 'not ok' "${answer}"

answer=$( ok "${PASS}" MyFirstTest )
assert_success $?
assert_equals 'ok' "${answer}"

TAP_VERBOSE=1
answer=$( ok "${PASS}" MyFirstTest )
assert_success $?
assert_equals "MyFirstTest .. ok 1 - 0" "${answer}"
TAP_VERBOSE=0
