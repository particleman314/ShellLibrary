#!/bin/sh

queue_name='testq'

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 5 "${answer}"

answer=$( queue_has --object "${queue_name}" --data '1' )
assert_false "${answer}"

answer=$( queue_has --object "${queue_name}" --data '3' )
assert_true "${answer}"

answer=$( queue_has --object "${queue_name}" --data '11' )
assert_false "${answer}"

answer=$( queue_has --object "${queue_name}" --data '89' )
assert_true "${answer}"

