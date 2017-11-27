#!/bin/sh

f1=$( make_output_file )
f2=$( make_output_file --prefix 'abc' )
f3=$( make_output_file --channel BLAH )
f4=$( make_output_file --prefix 'xyz' --channel 'ABC' )

result=$( get_latest_output_file )
assert_success $?
assert_equals "${f4}" "${result}"

__cleanup_filemgr
