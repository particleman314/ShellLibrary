#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

__get_section_from_file_by_lineno
assert_failure $?

__get_section_from_file_by_lineno "${TEST_INI_FILE}"
assert_failure $?

answer="$( __get_section_from_file_by_lineno "${TEST_INI_FILE}" 'non_present_section' )"
assert_failure $?
assert_equals '0:0' "${answer}"
detail "BeginLine/EndLine (non_present_section): ${answer}"

answer="$( __get_section_from_file_by_lineno "${TEST_INI_FILE}" 'temporary' )"
assert_success $?
assert_not_empty "${answer}"
detail "BeginLine/EndLine (temporary): ${answer}"

answer="$( __get_section_from_file_by_lineno "${TEST_INI_FILE}" 'git' )"
assert_success $?
assert_not_empty "${answer}"
detail "BeginLine/EndLine (git): ${answer}"

discard
