#!/bin/sh

sample_file1="${SLCF_SHELL_TOP}/test/${TEST_FULL_SAMPLE}"
sample_file2="${SLCF_SHELL_TOP}/test/${TEST_ONLY_DISCLAIMER}"
sample_file3="${SLCF_SHELL_TOP}/test/${TEST_ONLY_PKGDETAIL}"

__has_disclaimer
assert_false $?

__has_disclaimer --file 'not_a_real_file'
assert_false $?

__has_disclaimer --file "${sample_file1}"
assert_true $?

__has_disclaimer --file "${sample_file2}"
assert_true $?

__has_disclaimer --file "${sample_file3}"
assert_false $?
