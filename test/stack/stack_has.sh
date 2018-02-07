#!/usr/bin/env bash

stack_name='tests'

for qinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${qinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 5 "${answer}"

answer=$( stack_has --object "${stack_name}" --data '1' )
assert_false "${answer}"

answer=$( stack_has --object "${stack_name}" --data '3' )
assert_true "${answer}"

answer=$( stack_has --object "${stack_name}" --data '11' )
assert_false "${answer}"

answer=$( stack_has --object "${stack_name}" --data '89' )
assert_true "${answer}"

