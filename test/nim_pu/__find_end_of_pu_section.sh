#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __find_end_of_pu_section )
RC=$?
assert_not_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __find_end_of_pu_section "${filename}" )
RC=$?
assert_not_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __find_end_of_pu_section "${filename}" 500 )
RC=$?
assert_equals 500 "${answer}"
assert_success "${RC}"

answer=$( __find_end_of_pu_section "${filename}" 6 )
RC=$?
assert_equals $( __get_line_count "${filename}" ) "${answer}"
assert_success "${RC}"

answer=$( __find_end_of_pu_section "${filename}" 42 )
RC=$?
assert_equals 47 "${answer}"
assert_success "${RC}"

answer=$( __find_end_of_pu_section "${filename}" 41 )
RC=$?
assert_equals 54 "${answer}"
assert_success "${RC}"

