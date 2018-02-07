#!/usr/bin/env bash

[ -f "${SLCF_SHELL_TOP}/test/filemgt/__setup_files.sh" ] && . "${SLCF_SHELL_TOP}/test/filemgt/__setup_files.sh" internal 

replace_line_in_file
assert_failure $?

replace_line_in_file --file "${TEST_FILE}"
assert_failure $?

replace_line_in_file --file "${TEST_FILE}" --replacement 'This'
assert_failure $?

replace_line_in_file --file "${TEST_FILE}" --pattern 'That'
assert_failure $?

replace_line_in_file --file "${TEST_FILE}" --pattern 'This' --replacement 'That'
assert_success $?
answer=$( find_matching_line_in_file --file "${TEST_FILE}" --pattern 'That' )
assert_success $?
assert_not_empty "${answer}"

schedule_for_demolition "${TEST_FILE}"
