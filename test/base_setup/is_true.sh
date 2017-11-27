#!/bin/sh

false_checks='f F false False FALSE no No NO n N'
true_checks='t T true True TRUE yes Yes YES y Y'

for tc in ${true_checks}
do
  assert_true $( is_true "${tc}" )
done

for fc in ${false_checks}
do
  assert_false $( is_true "${fc}" )
done
