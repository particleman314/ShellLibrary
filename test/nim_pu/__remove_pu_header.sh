#!/bin/sh

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __remove_pu_header )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __remove_pu_header 'no_real_file' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __remove_pu_header "${filename}" )
RC=$?
assert_not_empty "${answer}"
assert_success "${RC}"
assert_is_file "${answer}"
assert_files_same --modify "${__NEGATIVE}" "${answer}" "${filename}"

[ "${answer}" != "${filename}" ] && schedule_for_demolition "${answer}"

