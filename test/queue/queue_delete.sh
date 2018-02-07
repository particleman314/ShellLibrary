#!/usr/bin/env bash

queue_name='testq'

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 5 "${answer}"

queue_delete --object "${queue_name}" --data 1
answer=$( queue_size --object "${queue_name}" )
assert_equals 5 "${answer}"

queue_delete --object "${queue_name}" --data 2
assert_success $?
answer=$( queue_size --object "${queue_name}" )
assert_equals 4 "${answer}"

queue_delete --object "${queue_name}" --data 10
answer=$( queue_size --object "${queue_name}" )
assert_equals 3 "${answer}"

queue_print --object "${queue_name}"

queue_delete --object "${queue_name}" --data 89

queue_print --object "${queue_name}"
answer=$( queue_size --object "${queue_name}" )
assert_equals 2 "${answer}"
