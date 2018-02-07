#!/usr/bin/env bash

wait_pids
assert_success $?

answer=$( wait_pids --pid 32541 )
assert_success $?
assert_not_empty "${answer}"

detail "${answer}"

answer=$( wait_pids --pid 32541 --suppress )
assert_success $?
assert_empty "${answer}"
