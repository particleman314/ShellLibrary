#!/bin/sh

queue_name='testq'

answer=$( queue_size --object "${queue_name}" )
assert_equals 0 "${answer}"

queue_add --object "${queue_name}" --data '1'
answer=$( queue_size --object "${queue_name}" )
assert_equals 1 "${answer}"

queue_clear --object "${queue_name}"
assert_success $?
answer=$( queue_size --object "${queue_name}" )
assert_equals 0 "${answer}"

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 5 "${answer}"

queue_add --object "${queue_name}" --data '1'
answer=$( queue_size --object "${queue_name}" )
assert_equals 6 "${answer}"

queue_clear --object "${queue_name}"
assert_success $?
answer=$( queue_size --object "${queue_name}" )
assert_equals 0 "${answer}"

queue_add --object "${queue_name}" --data '4' --unique
answer=$( queue_size --object "${queue_name}" )
assert_equals 1 "${answer}"
