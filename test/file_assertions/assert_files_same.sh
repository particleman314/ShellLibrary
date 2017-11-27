#!/bin/sh

file1="${SLCF_SHELL_TOP}/test/file_assertions/assert_files_same.sh"
file2="${SLCF_SHELL_TOP}/test/file_assertions/assert_files_same.sh"

std_opts="--suppress ${YES} --dnr"

assert_files_same ${std_opts}
assert_failure "$(__get_last_result )"

assert_files_same  ${std_opts} "${file1}"
assert_failure "$(__get_last_result )"

assert_files_same  ${std_opts} "${file2}" "${file2}"
assert_success "$(__get_last_result )"

file1="${SLCF_SHELL_TOP}/test/file_assertions/assert_has_filesize.sh"
assert_files_same  ${std_opts} "${file1}" "${file2}"
assert_failure "$(__get_last_result )"

detail "File 1 : ${file1} -- File 2 : ${file2}"

__reset_assertion_counters
