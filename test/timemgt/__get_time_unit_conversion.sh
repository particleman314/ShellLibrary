#!/usr/bin/env bash

answer=$( __get_time_unit_conversion )
assert_failure $?
assert_empty "${answer}"

answer=$( __get_time_unit_conversion --from 'seconds' )
assert_failure $?
assert_empty "${answer}"

answer=$( __get_time_unit_conversion --to 'seconds' )
assert_failure $?
assert_empty "${answer}"

answer=$( __get_time_unit_conversion --from 'months' --to 'minutes' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 43200 "${answer}"

answer=$( __get_time_unit_conversion --from 'seconds' --to 'seconds' )
assert_success $?
assert_equals 1 "${answer}"

answer=$( __get_time_unit_conversion --from 'minutes' --to 'hours' )
assert_success $?
assert_equals '.016' "${answer}"

detail "Inverted answer = ${answer}"
