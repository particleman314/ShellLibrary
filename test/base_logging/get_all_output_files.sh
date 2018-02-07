#!/usr/bin/env bash

result=$( make_output_file )
result=$( make_output_file --prefix 'abc' )
result=$( make_output_file --channel BLAH )
result=$( make_output_file --prefix 'xyz' --channel 'ABC' )

result=$( get_all_output_files )
assert_success $?
assert_comparison --comparison '>' $( __get_line_count "${result}" ) 0

__cleanup_filemgr
