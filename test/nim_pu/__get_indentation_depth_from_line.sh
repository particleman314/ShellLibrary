#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __get_indentation_depth_from_line )
RC=$?
assert_not_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __get_indentation_depth_from_line "${filename}" )
RC=$?
detail "Answer = ${answer}"
assert_not_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __get_indentation_depth_from_line "${filename}" 10 )
RC=$?
assert_equals 0 "${answer}"
assert_success "${RC}"

answer=$( __get_indentation_depth_from_line "${filename}" 42 )
RC=$?
assert_equals 2 "${answer}"
assert_success "${RC}"

answer=$( __get_indentation_depth_from_line "${filename}" 90 )
RC=$?
assert_not_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __get_indentation_depth_from_line 'abc  PDS_I  5  1234' )
RC=$?
assert_equals 0 "${answer}"
assert_success "${RC}"

answer=$( __get_indentation_depth_from_line '   abc  PDS_I  5  1234' )
RC=$?
assert_equals 3 "${answer}"
assert_success "${RC}"

