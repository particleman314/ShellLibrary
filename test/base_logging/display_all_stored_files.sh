#!/bin/sh

result=$( make_output_file )
result=$( make_output_file --prefix 'abc' )
result=$( make_output_file --channel BLAH )
result=$( make_output_file --prefix 'xyz' --channel 'ABC' )

append_output --channel 'BLAH' --data 'Test Output to see if it is stored into file'

display_all_stored_files
assert_success $?

__cleanup_filemgr
