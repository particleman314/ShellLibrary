#!/bin/sh

file_nonmatch="${SLCF_SHELL_TOP}/lib/networkmgt.sh"
file_match="${SLCF_SHELL_TOP}/lib/assertions.sh"

lineid=$( find_matching_line_in_file )
assert_failure $?

lineid=$( find_matching_line_in_file --pattern 'assert_equals' )
assert_failure $?

[ ! -f "${file_non_match}" ] && force_skip

lineid=$( find_matching_line_in_file --file "${file_nonmatch}" )
assert_success $?
assert_equals 0 "${lineid}"

lineid=$( find_matching_line_in_file --file "${file_nonmatch}" --pattern 'assert_equals')
assert_failure $?
assert_equals '0' "${lineid}"

clear_force_skip

[ ! -f "${file_non_match}" ] && force_skip

lineid=$( find_matching_line_in_file --file "${file_match}" --pattern 'assert_equals' )
assert_success $?
assert_not_empty "${lineid}"

clear_force_skip
