#!/usr/bin/env bash

queue_name='testq'

queue_peek --object "${queue_name}"
answer=$( __get_last_queue_result )
assert_empty "${answer}"

queue_add --object "${queue_name}" --data 1

queue_peek --object "${queue_name}"
answer=$( __get_last_queue_result )
assert_equals 1 "${answer}"

answer=$( queue_size --object "${queue_name}" )
assert_equals 1 "${answer}"

queue_print --object "${queue_name}"
