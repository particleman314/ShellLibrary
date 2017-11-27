#!/bin/sh

current_qm="${QUIET_MODE}"
QUIET_MODE="${YES}"

status
assert_failure $?

answer=$( status --lock-file 'abc' )
assert_failure $?
assert_not_empty "${answer}"

detail "[LF = abc] : ${answer}"

answer=$( status --program 'bash' )
assert_success $?
assert_not_empty "${answer}"

detail "[P = bash] : ${answer}"

QUIET_MODE="${current_qm}"