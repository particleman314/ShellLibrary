#!/usr/bin/env bash

queue_name='testq'

answer=$( queue_data --object "${queue_name}" )
assert_empty "${answer}"

answer=$( queue_size --object "${queue_name}" )
assert_equals 0 "${answer}"

queue_add --object "${queue_name}" --data 1
answer=$( queue_data --object "${queue_name}" )
assert_equals 1 "${answer}"

detail "Completed queue testing"
for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 6 "${answer}"
answer=$( queue_data --object "${queue_name}" )
assert_equals '1 2 3 4 10 89' "${answer}"

detail "Completed queue testing"
