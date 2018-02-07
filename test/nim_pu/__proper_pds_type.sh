#!/usr/bin/env bash

answer=$( __proper_pds_type )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __proper_pds_type 'PDS_I' )
RC=$?
assert_not_empty "${answer}"
assert_equals 'PDS_I' "${answer}"
assert_success "${RC}"

answer=$( __proper_pds_type 'PDS_PDSS' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"
