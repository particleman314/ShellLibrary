#!/bin/sh

sample_file1="${SLCF_SHELL_TOP}/test/${TEST_ONLY_DISCLAIMER}"

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/scriptgen.txt"
\touch "${tmpfile}"

assert_not_empty "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

add_disclaimer
assert_failure $?

add_header --file "${tmpfile}"
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"
\touch "${tmpfile}"
add_disclaimer --file "${tmpfile}" --contentfile "${sample_file1}"
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"
\touch "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

add_disclaimer --file "${tmpfile}" --contentfile "${SLCF_SHELL_TOP}/lib/constants.sh"
assert_success $?
assert_files_same "${tmpfile}" "${SLCF_SHELL_TOP}/lib/constants.sh"

\rm -f "${tmpfile}"