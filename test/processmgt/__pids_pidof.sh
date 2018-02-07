#!/usr/bin/env bash

__pids_pidof
assert_failure $?

answer=$( __pids_pidof bash )
assert_success $?
assert_not_empty "${answer}"

detail "${answer}"
