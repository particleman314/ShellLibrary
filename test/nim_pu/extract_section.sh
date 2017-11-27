#!/bin/sh

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

newfile=$( extract_section )
RC=$?
assert_failure "${RC}"
assert_empty "${newfile}"

newfile=$( extract_section --filename "${filename}" )
RC=$?
assert_failure "${RC}"
assert_empty "${newfile}"

newfile=$( extract_section --filename 'not_real_file' --key 'spooler_capabilities' )
RC=$?
assert_failure "${RC}"
assert_empty "${newfile}"

newfile=$( extract_section --filename "${filename}" --key 'spooler' )
RC=$?
assert_failure "${RC}"
assert_empty "${newfile}"

newfile=$( extract_section --filename "${filename}" --key 'spooler_capabilities' )
RC=$?
assert_success "${RC}"
assert_not_empty "${newfile}"

schedule_for_demolition "${newfile}"
