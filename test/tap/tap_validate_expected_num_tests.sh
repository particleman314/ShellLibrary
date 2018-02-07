#!/usr/bin/env bash

answer=$( tap_validate_expected_num_tests )
assert_success $?
assert_not_empty "${answer}"
assert_equals 0 "${answer}"
