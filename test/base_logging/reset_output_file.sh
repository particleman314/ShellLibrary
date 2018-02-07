#!/usr/bin/env bash

f1=$( make_output_file )
f2=$( make_output_file --prefix 'abc' )
f3=$( make_output_file --channel BLAH )
f4=$( make_output_file --prefix 'xyz' --channel 'ABC' )

reset_output_file
assert_failure $?

before_fs=$( __calculate_filesize "${f4}" )
append_output --channel 'ABC' --data 'Sample Data'
after_fs=$( __calculate_filesize "${f4}" )
assert_not_equals "${before_fs}" "${after_fs}"

reset_output_file --channel 'XYZ'
assert_failure $?

reset_output_file --channel 'ABC'
new_fs=$( __calculate_filesize "${f4}" )
assert_not_equals "${after_fs}" "${new_fs}"
assert_equals "${before_fs}" "${new_fs}"

__cleanup_filemgr
