#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

assert_true $( hexists --map "${TRIAL_MAP}" --key robot )
assert_false $( hexists --map "${TRIAL_MAP}" --key blah )
assert_true $( hexists --map "${TRIAL_MAP}" --key hub )

assert_false $( hexists )
assert_false $( hexists --map 'nomap' --key 'hi' )
