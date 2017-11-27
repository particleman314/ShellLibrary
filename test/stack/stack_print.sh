#!/bin/sh

stack_name='tests'

stack_push --object "${stack_name}" --data 1

for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done

answer="$( stack_print --object "${stack_name}" )"
assert_equals 'Stack : 89 10 4 3 2 1' "${answer}"
