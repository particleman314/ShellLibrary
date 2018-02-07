#!/usr/bin/env bash

answer=$( is_channel_in_use )
assert_failure $?
assert_false "${answer}"

answer=$( is_channel_in_use --channel BLAH )
assert_success $?
assert_false "${answer}"

result=$( make_output_file --prefix 'abc' )
assert_not_empty "${result}"
assert_match 'abc.' "${result}"
assert_is_file "${result}"

channel=$( find_output_channel --file "${result}" )
assert_not_empty "${channel}"

answer=$( is_channel_in_use --channel "${channel}" )
assert_success $?
assert_true "${answer}"

__cleanup_filemgr
