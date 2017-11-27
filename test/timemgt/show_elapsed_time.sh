#!/bin/sh

current_time=$( date "+%s" )

sleep_func -s 3 --old-version

answer=$( show_elapsed_time --start-time "${current_time}" )
detail "${current_time} -- ${answer}"

assert_comparison --comparison '>=' $( __extract_seconds "${answer}" ) 3
assert_success $?
