#!/bin/sh

assert_not_empty "${TRIAL_MAP}"

assert 2 $( hcount --map "${TRIAL_MAP}" )

hdel --map "${TRIAL_MAP}"
assert_failure $?

assert 2 $( hcount --map "${TRIAL_MAP}" )

hdel --map "${TRIAL_MAP}" --key 'robot'
assert_success $?

assert 1 $( hcount --map "${TRIAL_MAP}" )
map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"
