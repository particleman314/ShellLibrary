#!/bin/sh

f1=$( make_output_file )
f2=$( make_output_file --prefix 'abc' )
f3=$( make_output_file --channel BLAH )
f4=$( make_output_file --prefix 'xyz' --channel 'ABC' )

result=$( find_output_channel )
assert_success $?
assert_equals 'ABC' "${result}"

result=$( find_output_channel --file "${f1}" )
assert_success $?
assert_equals 'FT_0' "${result}"

result=$( find_output_channel --file "${SLCF_TEMPDIR}/blah" )
assert_failure $?

result=$( find_output_channel --file "${f3}" )
assert_success $?
assert_equals 'BLAH' "${result}"

__cleanup_filemgr
