#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

__get_section_from_file
assert_failure $?

__get_section_from_file "${TEST_INI_FILE}"
assert_failure $?

__get_section_from_file "${TEST_INI_FILE}" 'non_present_section'
assert_failure $?

answer="$( __get_section_from_file "${TEST_INI_FILE}" 'temporary' )"
assert_success $?
assert_not_empty "${answer}"
assert_is_file "${answer}"
detail "Temporary file : ${answer}"

answer="$( __get_section_from_file "${TEST_INI_FILE}" 'git' "${YES}" )"
assert_success $?
assert_not_empty "${answer}"

detail "Content of section 'git' :"
detail "${answer}"

discard
