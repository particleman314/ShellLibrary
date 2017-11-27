#!/bin/sh

dir="${SUBSYSTEM_TEMPORARY_DIR}"
file1="$( which ls )"
file2="${SLCF_SHELL_TOP}/test/file_assertions/assert_is_directory.sh"

std_opts="--suppress ${YES} --dnr"

assert_is_executable ${std_opts}
assert_failure "$( __get_last_result )"

detail "${file1}"
assert_is_executable ${std_opts} "${file1}"
assert_success "$( __get_last_result )"

detail "${file2}"
assert_is_executable ${std_opts} "${file2}"
assert_success "$( __get_last_result )"

detail "${dir}"
assert_is_executable ${std_opts} "${dir}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
