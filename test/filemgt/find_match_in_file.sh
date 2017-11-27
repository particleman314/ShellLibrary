#!/bin/sh

file_nonmatch="${SLCF_SHELL_TOP}/lib/networkmgt.sh"
file_match="${SLCF_SHELL_TOP}/lib/assertions.sh"

find_match_in_file
assert_failure $?

find_match_in_file --pattern 'assert_equals'
assert_failure $?

[ ! -f "${file_non_match}" ] && force_skip

find_match_in_file --file "${file_nonmatch}"
assert_success $?

answer=$( find_match_in_file --file "${file_nonmatch}" --pattern 'assert_equals' )
assert_failure $?
assert_empty "${answer}"

clear_force_skip

[ ! -f "${file_match}" ] && force_skip

answer=$( find_match_in_file --file "${file_match}" --pattern 'assert_equals' )
assert_success $?
assert_not_empty "${answer}"

clear_force_skip
