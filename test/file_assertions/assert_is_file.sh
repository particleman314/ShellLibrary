#!/bin/sh

dir="${SUBSYSTEM_TEMPORARY_DIR}"
file="${SLCF_SHELL_TOP}/test/file_assertions/assert_is_directory.sh"

std_opts="--suppress ${YES} --dnr"

assert_is_file ${std_opts}
assert_failure "$( __get_last_result )"

assert_is_file ${std_opts} "${file}"
assert_success "$( __get_last_result )"

assert_is_file ${std_opts} "${dir}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
