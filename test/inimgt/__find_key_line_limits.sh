#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

answer="$( __find_key_line_limits )"
assert_failure $?

answer="$( __find_key_line_limits "${TEST_INI_FILE}" )"
assert_failure $?

answer="$( __find_key_line_limits "${TEST_INI_FILE}" 'git' )"
assert_failure $?

answer="$( __find_section_line_limits "${TEST_INI_FILE}" 'nonexistent' 'gittoken' )"
assert_failure $?

answer="$( __find_key_line_limits "${TEST_INI_FILE}" 'git' 'gittoken' )"
assert_success $?
assert_equals '100:100' "${answer}"
detail "Line limits for key (git:gittoken} : ${answer}"

answer="$( __find_key_line_limits "${TEST_INI_FILE}" 'python' 'python_version_map' )"
assert_success $?
assert_equals '89:90' "${answer}"
detail "Line limits for key (python:python_version_map) : ${answer}"
