#!/usr/bin/env bash

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/test_discard.txt"
\touch "${tmpfile}"

assert_is_file "${tmpfile}"

register_tmpfile --filename "${tmpfile}"
discard_file="$( find_output_file --channel __global_DISCARD )"

assert_is_file "${discard_file}"
assert_not_equals 0 $( __calculate_filesize "${discard_file}" )

discard
