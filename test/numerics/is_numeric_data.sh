#!/bin/sh

true_checks='1 10 1.1 1e3 -6e-4'
#true_checks='1 10 1.1 -1 -1.6'
false_checks="'' ghfysd"

for tc in ${true_checks}
do
  answer=$( is_numeric_data --data "${tc}" )
  assert_equals 1 "${answer}"
done

for fc in ${false_checks}
do
  answer=$( is_numeric_data --data "${fc}" )
  assert_equals 0 "${answer}"
done
