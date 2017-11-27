#!/bin/sh

sample_file1="${SLCF_SHELL_TOP}/test/${TEST_ONLY_DISCLAIMER}"
sample_file2="${SLCF_SHELL_TOP}/test/${TEST_ONLY_PKGDETAIL}"

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/scriptgen.txt"
\touch "${tmpfile}"

assert_not_empty "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

__add_content_file
assert_failure $?

__add_content_file --contentfile "${sample_file1}"
assert_failure $?

assert_is_file "${sample_file1}"
__add_content_file --file "${tmpfile}" --contentfile "${sample_file1}"
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"
\touch "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

assert_is_file "${sample_file2}"
__add_content_file --file "${tmpfile}" --contentfile "${sample_file2}"
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"