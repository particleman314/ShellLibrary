#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

answer="$( __find_section_line_limits )"
assert_failure $?

answer="$( __find_section_line_limits "${TEST_INI_FILE}" )"
assert_failure $?

answer="$( __find_section_line_limits "${TEST_INI_FILE}" 'git' )"
assert_success $?
assert_equals '92:100' "${answer}"

answer="$( __find_section_line_limits "${TEST_INI_FILE}" 'nonexistent' )"
assert_failure $?
