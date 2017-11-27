#!/bin/sh

answer=$( define_semaphore_file )
assert_failure $?

answer=$( define_semaphore_file --semtype 'abc' )
assert_success $?
assert_equals 'abc.sem' "${answer}"

answer=$( define_semaphore_file --semtype 'xyz' --tag 'now' )
assert_success $?
assert_equals 'xyz_now.sem' "${answer}"
