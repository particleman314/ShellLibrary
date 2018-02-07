#!/usr/bin/env bash

answer="$( full_decode )"
assert_success $?
assert_empty "${answer}"

answer="$( full_decode 'xyz' )"
assert_success $?
assert_not_empty "${answer}"
assert_equals 'xyz' "${answer}"

answer="$( full_decode 'ENC{{{dDNzdGk5}}}' )"
assert_success $?
assert_not_empty "${answer}"
assert_equals 't3sti9' "${answer}"
