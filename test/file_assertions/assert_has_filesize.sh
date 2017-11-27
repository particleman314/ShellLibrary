#!/bin/sh

file="${SLCF_SHELL_TOP}/lib/file_assertions.sh"

std_opts="--suppress ${YES} --dnr"

assert_has_filesize ${std_opts}
assert_failure "$( __get_last_result )"

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/empty_file.data"
schedule_for_demolition "${tmpfile}"
touch "${tmpfile}"

assert_has_filesize ${std_opts} "${tmpfile}"
assert_failure "$( __get_last_result )"

assert_has_filesize ${std_opts} "${file}"
assert_success "$( __get_last_result )"

detail "File --> ${file}"

__reset_assertion_counters
