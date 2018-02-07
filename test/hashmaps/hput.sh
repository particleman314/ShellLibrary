#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

hput --map "${TRIAL_MAP}" --key count --value 1
assert_success $?
assert 1 $( hget --map "${TRIAL_MAP}" --key count )

hput --map "${TRIAL_MAP}" --key hub --value '1.2.3.4'
assert_success $?
assert '1.2.3.4' $( hget --map "${TRIAL_MAP}" --key hub )

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

hput
assert_failure $?

hput --map "${TRIAL_MAP}"
assert_failure $?

hput --map "${TRIAL_MAP}" --key newkey
assert_failure $?
