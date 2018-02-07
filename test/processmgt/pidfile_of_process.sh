#!/usr/bin/env bash

pidfile_of_process
assert_failure $?

answer=$( pidfile_of_process --base bash )
assert_success $?
assert_not_empty "${answer}"
detail "${answer}"
