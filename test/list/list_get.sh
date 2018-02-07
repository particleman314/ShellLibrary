#!/usr/bin/env bash

list_name='testl'

answer=$( list_get --object "${list_name}" )
assert_empty "${answer}"

list_add --object "${list_name}" --data 1

answer=$( list_get --object "${list_name}" --index 1 )
assert_equals 1 "${answer}"

list_print --object "${list_name}"

list_add --object "${list_name}" --data 7
list_add --object "${list_name}" --data 27
list_add --object "${list_name}" --data 675 --index 2

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}" --in-front
done
answer=$( list_size --object "${list_name}" )
assert_equals 9 "${answer}"

list_print --object "${list_name}"
assert_equals '89 10 4 3 2 1 675 7 27' "$( list_data --object "${list_name}" )"

answer=$( list_get --object "${list_name}" --index 3 )
assert_success $?
assert_equals 4 "${answer}"

list_print --object "${list_name}"

answer=$( list_get --object "${list_name}" --index 1 )
assert_success $?
assert_equals 89 "${answer}"
