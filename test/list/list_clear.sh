#!/bin/sh

list_name='testl'

answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"

list_add --object "${list_name}" --data '1'
answer=$( list_size --object "${list_name}" )
assert_equals 1 "${answer}"

list_clear --object "${list_name}"
assert_success $?
answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done
answer=$( list_size --object "${list_name}" )
assert_equals 5 "${answer}"

list_add --object "${list_name}" --data '1'
answer=$( list_size --object "${list_name}" )
assert_equals 6 "${answer}"

list_clear --object "${list_name}"
assert_success $?
answer=$( list_size --object "${list_name}" )
assert_equals 0 "${answer}"
