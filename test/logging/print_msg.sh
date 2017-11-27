#!/bin/sh

detail "Starting test for method : $1"

print_msg
assert_success $?

print_msg --message "Hello World"
assert_success $?

print_msg --color ${BRIGHT_RED} --message "Hello World in Red"
assert_success $?

print_msg --color ${BRIGHT_GREEN} --message "Christmas" --channel STDOUT
assert_success $?

detail "Ending test for method : $1"
