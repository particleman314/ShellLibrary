#!/usr/bin/env bash

queue_name='testq'

queue_add --object "${queue_name}" --data '1'
answer=$( queue_size --object "${queue_name}" )
assert_equals 1 "${answer}"

queue_add --object "${queue_name}" --data '5' --priority 40
assert_success $?
answer=$( queue_size --object "${queue_name}" )
assert_equals 2 "${answer}"

for qinsert in 2 3 4 10 89
do
  queue_add --object "${queue_name}" --data "${qinsert}" --priority "${qinsert}"
done
answer=$( queue_size --object "${queue_name}" )
assert_equals 7 "${answer}"

answer=$( queue_get_associated_priority --object "${queue_name}" --match 1 )
assert_success $?
assert_equals $( __get_priority_level ) ${answer}

answer=$( queue_get_associated_priority --object "${queue_name}" --match 4 )
assert_success $?
assert_equals 4 "${answer}"

default_priority=$( __get_priority_level )
__set_priority_level 45

queue_add --object "${queue_name}" --data '75'
answer=$( queue_get_associated_priority --object "${queue_name}" --match 75 )
assert_success $?
assert_equals 45 "${answer}"

queue_print --object "${queue_name}"

__set_priority_level "${default_priority}"
