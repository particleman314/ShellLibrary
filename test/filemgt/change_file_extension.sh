#!/usr/bin/env bash

[ -f "${SLCF_SHELL_TOP}/test/filemgt/__setup_files.sh" ] && . "${SLCF_SHELL_TOP}/test/filemgt/__setup_files.sh" external

testfile_dirname1=$( dirname "${TEST_FILE1}" )
testfile_dirname2=$( dirname "${TEST_FILE2}" )

change_file_extension
assert_failure $?

change_file_extension --extension abc
assert_failure $?

detail "TEST_FILE1 = ${TEST_FILE1}"
answer=$( change_file_extension --extension abc --file "${TEST_FILE1}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals "${testfile_dirname1}/sample_file.abc" "${answer}"

added_extension='ghi'

answer=$( change_file_extension --extension "${added_extension}" --file "${TEST_FILE2}" )
assert_success $?
assert_equals "${testfile_dirname2}/sample_file.${added_extension}" "${answer}"
