#!/bin/sh

answer=$( __pids_pidof bash )
assert_not_empty "${answer}"

for i in ${answer}
do
  checkpid ${i}
  assert_success $?
done

checkpid 99999
assert_failure $?
