#!/usr/bin/env bash

answer_start=$( show_start_time )
assert_success $?
assert_not_empty "${answer_start}"

sleep_func -s 1 --old-version

answer_end=$( show_end_time )
assert_success $?
assert_not_empty "${answer_end}"
