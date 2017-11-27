#!/bin/sh

f1=$( make_output_file )
f2=$( make_output_file --prefix 'abc' )
f3=$( make_output_file --channel BLAH )
f4=$( make_output_file --prefix 'xyz' --channel 'ABC' )

result=$( get_latest_generated_output_channel )
assert_success $?
assert_equals 'FT_1' "${result}"

__cleanup_filemgr
