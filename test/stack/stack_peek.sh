#!/usr/bin/env bash

stack_name='tests'

stack_peek --object "${stack_name}"
answer=$( __get_last_stack_result )
assert_empty "${answer}"

stack_push --object "${stack_name}" --data 10

stack_peek --object "${stack_name}"
answer=$( __get_last_stack_result )
assert_equals 10 "${answer}"
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"

stack_print --object "${stack_name}"
