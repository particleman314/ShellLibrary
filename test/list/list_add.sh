#!/bin/sh

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
answer=$( list_size --object "${list_name}" )
assert_equals 6 "${answer}"

list_add --object "${list_name}" --data 1
answer=$( list_size --object "${list_name}" )
assert_equals 7 "${answer}"

assert_equals '1 2 3 4 10 89 1' "$( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 4 --unique
assert_failure $?
answer=$( list_size --object "${list_name}" )
assert_equals 7 "${answer}"

assert_equals '1 2 3 4 10 89 1' "$( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 35 --unique
assert_success $?
answer=$( list_size --object "${list_name}" )
assert_equals 8 "${answer}"

assert_equals '1 2 3 4 10 89 1 35' "$( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 6 --in-front
assert_success $?
answer=$( list_size --object "${list_name}" )
assert_equals 9 "${answer}"
assert_equals '6 1 2 3 4 10 89 1 35' "$( list_data --object "${list_name}" )"

detail "Data Before = $( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 99 --index 3
answer=$( list_size --object "${list_name}" )
assert_equals 10 "${answer}"
assert_equals '6 1 99 2 3 4 10 89 1 35' "$( list_data --object "${list_name}" )"

detail "Data After = $( list_data --object "${list_name}" )"

list_add --object "${list_name}" --data 99 --index 8 --unique
answer=$( list_size --object "${list_name}" )
assert_equals 10 "${answer}"
assert_equals '6 1 99 2 3 4 10 89 1 35' "$( list_data --object "${list_name}" )"

list_clear --object "${list_name}"

list_add --object "${list_name}" --data '99' --index 3
answer=$( list_size --object "${list_name}" )
assert_equals 1 "${answer}"
assert_equals '99' "$( list_data --object "${list_name}" )"
