#!/bin/sh

stack_name='tests'

answer=$( stack_data --object "${stack_name}" )
assert_empty "${answer}"

answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_data --object "${stack_name}" )
assert_equals 1 "${answer}"

detail "Completed stack testing"
for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 6 "${answer}"
answer=$( stack_data --object "${stack_name}" )
assert_equals '89 10 4 3 2 1' "${answer}"

detail "Completed stack testing"
