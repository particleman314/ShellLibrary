#!/bin/sh

stack_name='tests'

for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 5 "${answer}"

stack_pop --object "${stack_name}"
answer=$( stack_size --object "${stack_name}" )
assert_equals 4 "${answer}"

stack_pop --object "${stack_name}"
assert_success $?
answer=$( stack_size --object "${stack_name}" )
assert_equals 3 "${answer}"

stack_pop --object "${stack_name}"
answer=$( stack_size --object "${stack_name}" )
assert_equals 2 "${answer}"

stack_print --object "${stack_name}"

stack_pop --object "${stack_name}"

stack_print --object "${stack_name}"
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"
