#!/bin/sh

list_name='testl'

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done
answer=$( list_size --object "${list_name}" )
assert_equals 5 "${answer}"

answer=$( list_find --object "${list_name}" --match '1' )
assert_empty "${answer}"

answer=$( list_find --object "${list_name}" --match '4' )
assert_success $?
assert_equals 3 "${answer}"

answer=$( list_find --object "${list_name}" --match '2' )
assert_success $?
assert_equals 1 "${answer}"

answer=$( list_find --object "${list_name}" --match '89' )
assert_success $?
assert_equals 5 "${answer}"
