#!/usr/bin/env bash

filename="${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( extract_from_pu_output )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( extract_from_pu_output --filename "${filename}" )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( extract_from_pu_output --key 'hubname' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( extract_from_pu_output --key 'hubname' --filename "${filename}" )
RC=$?
detail "Answer = ${answer}"
assert_equals 'hubname PDS_PCH 10 db-2-sh01' "${answer}"
assert_success "${RC}"

answer=$( extract_from_pu_output --key 'sessions/0/address' --filename "${filename}" )
RC=$?
detail "Answer = ${answer}"
assert_equals 'address PDS_PCH 16 127.0.0.1/53781' "${answer}"
assert_success "${RC}"
