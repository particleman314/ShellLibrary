#!/bin/sh

list_name='testl'

for linsert in 2 3 4 10 89
do
  list_add --object "${list_name}" --data "${linsert}"
done

answer=$( list_size --object "${list_name}" )
assert_equals 5 "${answer}"

answer=$( list_has --object "${list_name}" --data 1 )
assert_false "${answer}"

answer=$( list_has --object "${list_name}" --data 3 )
assert_true "${answer}"

answer=$( list_has --object "${list_name}" --data 11 )
assert_false "${answer}"

answer=$( list_has --object "${list_name}" --data 89 )
assert_true "${answer}"

