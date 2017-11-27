#!/bin/sh

result=$( make_output_file )
result=$( make_output_file --prefix 'abc' )
result=$( make_output_file --channel BLAH )
result=$( make_output_file --prefix 'xyz' --channel 'ABC' )

before_numfiles=$( get_number_output_files )
remove_all_output_files
assert_success $?

after_numfiles=$( get_number_output_files )
assert_greater_equal "${after_numfiles}" 0
assert_not_equals "${before_numfiles}" "${after_numfiles}"

detail "${before_numfiles} -- ${after_numfiles}"

__cleanup_filemgr
