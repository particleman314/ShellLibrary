#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __find_pu_section_by_depth )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_pu_section_by_depth 'not_a_real_file' )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_pu_section_by_depth "${filename}" -1 )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer=$( __find_pu_section_by_depth "${filename}" 1000 )
RC=$?
assert_empty "${answer}"
assert_success "${RC}"

answer=$( __find_pu_section_by_depth "${filename}" 1 )
RC=$?
assert_not_empty "${answer}"
assert_success "${RC}"

detail "Answer = ${answer}"
[ "${answer}" != "${filename}" ] && schedule_for_demolition "${answer}"

