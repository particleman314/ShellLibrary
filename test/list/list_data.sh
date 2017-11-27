#!/bin/sh

list_name='testl'

answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"

list_add --object "${list_name}" --data 1
answer=$( list_size --object "${list_name}" )
assert_equals 1 "${answer}"
assert_equals 1 "$( list_data --object "${list_name}" )"

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done
assert_equals '1 2 3 4 10 89' "$( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 1
assert_equals '1 2 3 4 10 89 1' "$( list_data --object "${list_name}" )"
