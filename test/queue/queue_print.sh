#!/bin/sh

queue_name='testq'

queue_add --object "${queue_name}" --data 1

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done

answer="$( queue_print --object "${queue_name}" )"
assert_equals 'Queue : 1 2 3 4 10 89' "${answer}"
