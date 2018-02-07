#!/usr/bin/env bash

answer=$( remove_characters )
assert_failure $?

answer=$( remove_characters --num-char 5 )
assert_failure $?

answer=$( remove_characters --num-char 3 --str 'Hello' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'He' "${answer}"

answer=$( remove_characters --num-char 10 --str 'Hello' )
assert_success $?
assert_empty "${answer}"
