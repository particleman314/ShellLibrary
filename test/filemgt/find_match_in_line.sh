#!/usr/bin/env bash

detail "Starting test for method : $1"

file_nonmatch="${SLCF_SHELL_TOP}/lib/networkmgt.sh"
file_match="${SLCF_SHELL_TOP}/lib/assertions.sh"

answer=$( find_match_in_line )
assert_failure $?
assert_false "${answer}"

answer=$( find_match_in_line --line "${file_nonmatch}" )
assert_failure $?
assert_false "${answer}"

answer=$( find_match_in_line --line "${file_match}" --pattern 'assertion' )
assert_success $?
assert_true "${answer}"

detail "Ending test for method : $1"
