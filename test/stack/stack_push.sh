#!/bin/sh

stack_name='tests'

answer=$( stack_size --object "${stack_name}" )
assert_equals 0 "${answer}"

stack_push --object "${stack_name}" --data 1
answer=$( stack_size --object "${stack_name}" )
assert_equals 1 "${answer}"

for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 6 "${answer}"

stack_push --object "${stack_name}" --data 1 --unique
answer=$( stack_size --object "${stack_name}" )
assert_equals 6 "${answer}"

stack_push --object "${stack_name}" --data 'aaa' --unique
answer=$( stack_size --object "${stack_name}" )
assert_equals 7 "${answer}"

answer="$( stack_data --object "${stack_name}" )"
assert_equals 'aaa 89 10 4 3 2 1' "${answer}"
