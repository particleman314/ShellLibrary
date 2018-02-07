#!/usr/bin/env bash

stack_name='tests'

answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"

for qinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${qinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 6 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_size --object "${stack_name}" )
assert_equals 7 "${answer}"

stack_push --object "${stack_name}" --data 4 --unique
answer=$( stack_size --object "${stack_name}" )
assert_equals 7 "${answer}"
