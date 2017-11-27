#!/bin/sh

answer=$( pass MyFirstTest )
assert_success $?
assert_equals 'ok' "${answer}"

TAP_VERBOSE=1
answer=$( pass MyFirstTest )
assert_success $?
assert_equals "MyFirstTest .. ok 1 - 0" "${answer}"
TAP_VERBOSE=0
