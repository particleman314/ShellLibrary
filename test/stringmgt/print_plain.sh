#!/usr/bin/env bash

answer=$( print_plain --message 'Hello World' )
assert_success $?

answer=$( print_plain --msg 'Hello Second Round' )
assert_success $?

answer=$( print_plain "Hello Third Round" )
assert_failure $?

answer=$( print_plain --message "Different format" --format "%q\n" )
assert_success $?
