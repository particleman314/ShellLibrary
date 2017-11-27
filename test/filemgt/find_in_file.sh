#!/bin/sh

file_nonmatch="${SLCF_SHELL_TOP}/lib/networkmgt.sh"
file_match="${SLCF_SHELL_TOP}/lib/assertions.sh"

find_in_file
assert_failure $?

find_in_file --data 'assert_equals'
assert_failure $?

[ ! -f "${file_non_match}" ] && force_skip

find_in_file --file "${file_nonmatch}"
assert_failure $?

find_in_file --file "${file_nonmatch}" --data 'assert_equals'
assert_failure $?

clear_force_skip

[ ! -f "${file_match}" ] && force_skip

find_in_file --file "${file_match}" --data 'assert_equals()'
assert_success $?

clear_force_skip