#!/bin/sh

f1=$( make_output_file )
f2=$( make_output_file --prefix 'abc' )
f3=$( make_output_file --channel BLAH )
f4=$( make_output_file --prefix 'xyz' --channel 'ABC' )

result=$( find_output_file )
assert_success $?
assert_equals "${f4}" "${result}"

result=$( find_output_file --channel "FT_0" )
assert_success $?
assert_equals "${f1}" "${result}"

result=$( find_output_file --channel "ABC2" )
assert_failure $?

result=$( find_output_file --channel 'BLAH' )
assert_success $?
assert_equals "${f3}" "${result}"

__cleanup_filemgr
