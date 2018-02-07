#!/usr/bin/env bash

list_name='testl'

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done
answer=$( list_size --object "${list_name}" )
assert_equals 5 "${answer}"

list_delete --object "${list_name}" --data '1'
answer=$( list_size --object "${list_name}" )
assert_equals 5 "${answer}"

list_delete --object "${list_name}" --data '2'
assert_success $?
answer=$( list_size --object "${list_name}" )
assert_equals 4 "${answer}"

list_delete --object "${list_name}" --data '10'
answer=$( list_size --object "${list_name}" )
assert_equals 3 "${answer}"

list_print --object "${list_name}"

list_delete --object "${list_name}" --data '89'

list_print --object "${list_name}"
answer=$( list_size --object "${list_name}" )
assert_equals 2 "${answer}"
