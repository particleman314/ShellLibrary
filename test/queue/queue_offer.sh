#!/bin/sh

queue_name='testq'

queue_offer --object "${queue_name}"
answer=$( __get_last_queue_result )
assert_empty "${answer}"

queue_add --object "${queue_name}" --data 1

detail "Queue Before = $( queue_data --object "${queue_name}" )"

queue_offer --object "${queue_name}"
answer=$( __get_last_queue_result )
assert_equals 1 "${answer}"

detail "Queue After = $( queue_data --object "${queue_name}" )"
answer=$( queue_size --object "${queue_name}" )
assert_equals 0 "${answer}"

queue_print --object "${queue_name}"

queue_add --object "${queue_name}" --data 7
queue_add --object "${queue_name}" --data 27
queue_add --object "${queue_name}" --data 675 --priority 50

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}" --priority "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 8 "${answer}"

queue_print --object "${queue_name}"

queue_offer --object "${queue_name}"
assert_success $?
answer=$( __get_last_queue_result )
assert_equals 7 "${answer}"

queue_print --object "${queue_name}"

queue_offer --object "${queue_name}" --next 
assert_success $?
answer=$( __get_last_queue_result )
assert_equals 2 "${answer}"

queue_print --object "${queue_name}"

answer=$( queue_size --object "${queue_name}" )
assert_equals 6 "${answer}"

detail "Completed queue testing"