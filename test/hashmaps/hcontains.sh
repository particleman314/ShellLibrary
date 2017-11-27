#!/bin/sh

assert_not_empty "${TRIAL_MAP}"

answer=$( hcontains --map "${TRIAL_MAP}" --key 'robot' --match '1.2.3.4' )
assert_success $?
assert_false "${answer}"

answer=$( hcontains --map "${TRIAL_MAP}" --key 'robot' --match '10.238.41.253' )
assert_success $?
assert_true "${answer}"

hadd_item --map "${TRIAL_MAP}" --key 'robot' --value '1.2.3.4'
assert_success $?

answer=$( hcontains --map "${TRIAL_MAP}" --key 'robot' --match '1.2.3.4' )
assert_success $?
assert_true "${answer}"
