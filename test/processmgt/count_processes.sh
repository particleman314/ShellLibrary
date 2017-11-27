#!/bin/sh

answer=$( count_processes )
assert_failure $?
assert_equals 0 "${answer}"

answer=$( count_processes --pidtype bash )
assert_success $?
assert_comparison --comparison '>' ${answer} 0

answer=$( count_processes --pidtype blah )
assert_success $?
assert_equals 0 ${answer}
