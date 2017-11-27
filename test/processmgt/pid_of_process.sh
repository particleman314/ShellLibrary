#!/bin/sh

answer=$( pid_of_process )
assert_failure $?
assert_empty "${answer}"

answer=$( pid_of_process --base 'bash' )
assert_success $?
assert_not_empty "${answer}"

detail "${answer}"
