#!/bin/sh

queue_name='testq'

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 5 "${answer}"

answer=$( queue_find --object "${queue_name}" --match '1' )
assert_empty "${answer}"

answer=$( queue_find --object "${queue_name}" --match '4' )
assert_success $?
assert_equals 3 "${answer}"

answer=$( queue_find --object "${queue_name}" --match '2' )
assert_success $?
assert_equals 1 "${answer}"

answer=$( queue_find --object "${queue_name}" --match '89' )
assert_success $?
assert_equals 5 "${answer}"
