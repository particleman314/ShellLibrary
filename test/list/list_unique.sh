#!/usr/bin/env bash

list_name='testl'

answer="$( list_unique --object "${list_name}" )"
assert_empty "${answer}"

list_add --object "${list_name}" --data 1
answer="$( list_unique --object "${list_name}" )"
assert_equals 1 "${answer}"

for linsert in 1 2 3 4 10 4 89 1
do
  list_add --object "${list_name}" --data "${linsert}"
done
answer=$( list_size --object "${list_name}" )
assert_equals 9 "${answer}"

answer="$( list_unique --object "${list_name}" )"
assert_equals '1 10 2 3 4 89' "${answer}"
