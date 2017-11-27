#!/bin/sh

list_name='testl'

list_add --object "${list_name}" --data 1

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done

answer="$( list_print --object "${list_name}" )"
assert_equals 'List : 1 2 3 4 10 89' "${answer}"
