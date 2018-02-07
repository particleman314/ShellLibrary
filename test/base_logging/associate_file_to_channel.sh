#!/usr/bin/env bash

associate_file_to_channel
assert_failure $?

associate_file_to_channel --channel BLAH
assert_failure $?

associate_file_to_channel --file 'tmp.xyz'
assert_failure $?

associate_file_to_channel --channel BLAH --file 'tmp.xyz'
assert_failure $?

result=$( make_output_file --prefix 'abc' )
assert_not_empty "${result}"
assert_match 'abc.' "${result}"
assert_is_file "${result}"

channel=$( find_output_channel --file "${result}" )
assert_not_empty "${channel}"

answer=$( get_number_output_files )
assert_greater_equals "${answer}" 1

associate_file_to_channel --channel "${channel}_2" --file "${result}"
assert_success $?

answer=$( get_number_output_files )
assert_greater_equals "${answer}" 2

display_all_stored_files

__cleanup_filemgr
