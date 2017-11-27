#!/bin/sh

list_name='testl'

answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"

list_add --object "${list_name}" --data '1'
answer=$( list_size --object "${list_name}" )
assert_equals 1 "${answer}"

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done

list_print --object "${list_name}"

list_delete --object "${list_name}" --data 2

list_print --object "${list_name}"

answer=$( list_size --object "${list_name}" )
assert_equals 2 "$( __get_last_list_result )"
assert_equals 5 "${answer}"
