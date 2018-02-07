#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

hput --map "${TRIAL_MAP}" --key count --value 1
assert_success $?
assert 1 $( hget --map "${TRIAL_MAP}" --key count )

hinc --map "${TRIAL_MAP}" --key count
assert_success $?
assert 2 $( hget --map "${TRIAL_MAP}" --key count )

hinc --map "${TRIAL_MAP}" --key count --incr 6
assert_success $?
assert 8 $( hget --map "${TRIAL_MAP}" --key count )
