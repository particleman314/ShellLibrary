#!/bin/sh

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __extract_matching_lines )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __extract_matching_lines 'not_a_real_file' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __extract_matching_lines "${filename}" )
RC=$?
assert_equals "${filename}" "${answer}"
assert_failure "${RC}"

answer=$( __extract_matching_lines "${filename}" '51:53' )
RC=$?
assert_not_empty "${answer}"
assert_is_file "${answer}"
assert_success "${RC}"

[ "${answer}" != "${filename}" ] && schedule_for_demolition "${answer}"

answer=$( __extract_matching_lines "${filename}" '1:6' '10:20' '51:53' )
RC=$?
assert_not_empty "${answer}"
assert_is_file "${answer}"
assert_success "${RC}"

[ "${answer}" != "${filename}" ] && schedule_for_demolition "${answer}"
