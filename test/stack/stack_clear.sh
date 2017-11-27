#!/bin/sh

stack_name='tests'

answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"

stack_clear --object "${stack_name}"
assert_success $?
answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done

answer=$( stack_size --object "${stack_name}" )
assert_equals 5 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_size --object "${stack_name}" )
assert_equals 6 "${answer}"

stack_clear --object "${stack_name}"
assert_success $?
answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

stack_push --object "${stack_name}" --data 4 --unique
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"
