#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

answer="$( __find_line_for_key )"
assert_failure $?

answer="$( __find_line_for_key "${TEST_INI_FILE}" )"
assert_failure $?

answer="$( __find_line_for_key "${TEST_INI_FILE}" 'git' )"
assert_failure $?

answer="$( __find_line_for_key "${TEST_INI_FILE}" 'git' 'gittoken' )"
assert_success $?
assert_not_empty "${answer}"
detail "Line for (gittoken) : ${answer}"

answer="$( __find_line_for_key "${TEST_INI_FILE}" 'git' 'gitblah' )"
assert_failure $?
