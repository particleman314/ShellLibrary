#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __find_pds_integer_names )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_pds_integer_names 'no_real_file' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_pds_integer_names "${filename}" )
RC=$?
assert_not_empty "${answer}"
assert_match 'lastrestart' "${answer}"

if [ $( __check_for --key 'DETAIL' --success ) -eq "${YES}" ]
then
  detail "Elements found :"
  for e in ${answer}
  do
    detail "   ${e}"
  done
fi
