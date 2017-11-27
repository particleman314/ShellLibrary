#!/bin/sh

stack_name='testq'

for sinsert in 2 3 4 10 89
do
  stack_push --object "${stack_name}" --data "${sinsert}"
done
answer=$( stack_size --object "${stack_name}" )
assert_equals 5 "${answer}"

answer=$( stack_find --object "${stack_name}" --match '1' )
assert_empty "${answer}"

answer=$( stack_find --object "${stack_name}" --match '4' )
assert_success $?
assert_equals 3 "${answer}"

answer=$( stack_find --object "${stack_name}" --match '2' )
assert_success $?
assert_equals 5 "${answer}"

answer=$( stack_find --object "${stack_name}" --match '89' )
assert_success $?
assert_equals 1 "${answer}"
