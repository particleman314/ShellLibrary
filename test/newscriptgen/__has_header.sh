#!/bin/sh

sample_file1="${SLCF_SHELL_TOP}/test/${TEST_FULL_SAMPLE}"
sample_file2="${SLCF_SHELL_TOP}/test/${TEST_ONLY_DISCLAIMER}"
sample_file3="${SLCF_SHELL_TOP}/test/${TEST_ONLY_PKGDETAIL}"

__has_header
assert_false $?

__has_header --file 'not_a_real_file'
assert_false $?

__has_header --file "${sample_file1}"
assert_true $?

__has_header --file "${sample_file2}"
assert_false $?

__has_header --file "${sample_file3}"
assert_true $?
