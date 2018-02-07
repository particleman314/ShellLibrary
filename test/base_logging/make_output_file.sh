#!/usr/bin/env bash

result=$( make_output_file )
assert_not_empty "${result}"
assert_match 'output.' "${result}"
assert_is_file "${result}"

result=$( make_output_file --prefix 'abc' )
assert_not_empty "${result}"
assert_match 'abc.' "${result}"
assert_is_file "${result}"

result=$( make_output_file --channel BLAH )
assert_not_empty "${result}"
assert_match 'output.' "${result}"
assert_is_file "${result}"

detail "Collecting output channels..."
result=$( get_all_output_channels | tr '\n' ' ' )
detail "Output Channels : ${result}"
assert_not_empty "${result}"
detail "RC = $( __get_last_result )"
assert_match 'BLAH' "${result}"

result=$( make_output_file --prefix 'xyz' --channel 'ABC' )
assert_not_empty "${result}"
assert_match 'xyz.' "${result}"
tags=$( get_all_output_channels | tr '\n' ' ' )
assert_match 'ABC' "${tags}"

__cleanup_filemgr
