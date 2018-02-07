#!/usr/bin/env bash

result=$( make_output_file --prefix 'abc' )
assert_not_empty "${result}"
assert_match 'abc.' "${result}"
assert_is_file "${result}"

channel=$( find_output_channel --file "${result}" )
assert_not_empty "${channel}"

mark_channel_persistent --channel "${channel}"
answer="$( is_channel_persistent --channel "${channel}" )"
echo "${answer}"
assert_true "${answer}"

mark_channel_persistent --channel "${channel}" --remove
answer="$( is_channel_persistent --channel "${channel}" )"
echo "${answer}"
assert_false "${answer}"

__cleanup_filemgr
