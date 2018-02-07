#!/usr/bin/env bash

list_name='testl'

answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"

list_add --object "${list_name}" --data 1
answer=$( list_size --object "${list_name}" )
assert_equals 1 "${answer}"

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done

detail "Data Before = $( list_data --object "${list_name}" )"

answer=$( list_size --object "${list_name}" )
assert_equals 6 "${answer}"

detail "Data After = $( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 1
answer=$( list_size --object "${list_name}" )
assert_equals 7 "${answer}"

list_add --object "${list_name}" --data 4 --unique
answer=$( list_size --object "${list_name}" )
assert_equals 7 "${answer}"
