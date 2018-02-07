#!/usr/bin/env bash

detail "Starting test for method : $1"

print_debug_msg
assert_success $?

#DEBUGGING=1
print_debug_msg --message "Hello World"
assert_success $?
#DEBUGGING=

print_debug_msg --color ${BRIGHT_RED} --message "Hello World in Red"
assert_success $?

print_debug_msg --color ${BRIGHT_GREEN} --message "Christmas" --channel STDOUT
assert_success $?

detail "Ending test for method : $1"
