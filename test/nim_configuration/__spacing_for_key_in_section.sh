#!/usr/bin/env bash

section='/test_config_basic'

answer=$( __spacing_for_key_in_section "${section}" )
assert_success $?
assert_equals 2 "${#answer}"

section='/hub/tunnel/certificates'
answer=$( __spacing_for_key_in_section "${section}" )
assert_success $?
assert_equals 6 "${#answer}"
