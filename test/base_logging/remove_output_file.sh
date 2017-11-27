#!/bin/sh

result=$( make_output_file )
result=$( make_output_file --prefix 'abc' )
result=$( make_output_file --channel BLAH )
result=$( make_output_file --prefix 'xyz' --channel 'ABC' )

remove_output_file
assert_failure $?

remove_output_file --channel 'XYZ'
assert_failure $?

remove_output_file --channel 'ABC'
assert_success $?
assert_empty "$( find_output_file --channel 'ABC' )"

display_all_stored_files

__cleanup_filemgr
