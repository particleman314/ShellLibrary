#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __determine_maximum_pu_output_depth )
RC=$?
assert_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __determine_maximum_pu_output_depth 'no_real_file' )
RC=$?
assert_equals 0 "${answer}"
assert_failure "${RC}"

answer=$( __determine_maximum_pu_output_depth "${filename}" )
RC=$?
assert_equals 2 "${answer}"
assert_success "${RC}"
