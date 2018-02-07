#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __find_key_at_depth )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_key_at_depth 'not_real_file' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_key_at_depth "${filename}" )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_key_at_depth "${filename}" 'hubname' 0 1 )
RC=$?
assert_not_empty "${answer}"
assert_equals 'db-2-sh01' $( get_pds_value --data "${answer}" )

answer=$( __find_key_at_depth "${filename}" 'address' 0 1 )
RC=$?
assert_not_empty "${answer}"
assert_equals '127.0.0.1/53781' $( get_pds_value --data "${answer}" )

answer=$( __find_key_at_depth "${filename}" 'address' 0 2 )
RC=$?
assert_not_empty "${answer}"
assert_equals '127.0.0.1/48002' $( get_pds_value --data "${answer}" )

answer=$( __find_key_at_depth "${filename}" 'address' 2 1 )
RC=$?
assert_not_empty "${answer}"
assert_equals '127.0.0.1/53781' $( get_pds_value --data "${answer}" )

answer=$( __find_key_at_depth "${filename}" 'address' 2 2 )
RC=$?
assert_not_empty "${answer}"
assert_equals '127.0.0.1/48002' $( get_pds_value --data "${answer}" )
