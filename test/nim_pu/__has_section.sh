#!/bin/sh

filename="${SLCF_SHELL_TOP}/test/${SAMPLE_PU_OUTPUT}"
assert_not_empty "${filename}"
assert_is_file "${filename}"

answer=$( __has_section )
assert_equals "${NO}" "${answer}"

answer=$( __has_section "${filename}" )
assert_equals "${NO}" "${answer}"

answer=$( __has_section "${filename}" 'hubname' )
assert_equals "${NO}" "${answer}"

answer=$( __has_section 'no_real_file' 'hubname' )
assert_equals "${NO}" "${answer}"

answer=$( __has_section "${filename}" 'sessions' )
assert_equals "${YES}" "${answer}"

answer=$( __has_section "${filename}" 'spooler_capabilities' )
assert_equals "${YES}" "${answer}"

answer=$( __has_section "${filename}" '0' )
assert_equals "${NO}" "${answer}"

