#!/usr/bin/env bash

add_pid
assert_failure $?

answer=$( __pids_pidof bash )
for p in ${answer}
do
  add_pid --pid "${p}" --description "Bash Shell - ${p}"
done

hprint --map 'pid_map'
