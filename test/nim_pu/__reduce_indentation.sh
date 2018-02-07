#!/usr/bin/env bash

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __determine_maximum_pu_output_depth "${filename}" )
assert_equals 2 "${answer}"

\cp -f "${filename}" "${filename}.temporary"
__reduce_indentation "${filename}.temporary"
assert_failure $?

__reduce_indentation "${filename}.temporary" 1
assert_success $?

answer=$( __determine_maximum_pu_output_depth "${filename}.temporary" )
detail "Maximum depth --> ${answer}"
assert_equals 1 "${answer}"

\cp -f "${filename}" "${filename}.temporary"
__reduce_indentation "${filename}.temporary" 2

answer=$( __determine_maximum_pu_output_depth "${filename}.temporary" )
detail "Maximum depth --> ${answer}"
assert_equals 0 "${answer}"

schedule_for_demolition "${filename}.temporary"

