#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

answer="$( ini_get_sections )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_sections --inifile "${TEST_INI_FILE}" )"
assert_success $?
detail "Sections found : ${answer}"
assert_not_empty "${answer}"

expected_sections_count=12
number_sections=$( __get_word_count "${answer}" )
assert_equals "${expected_sections_count}" "${number_sections}"

answer="$( ini_get_sections --inifile 'NoIniSections.txt' )"
assert_success $?
assert_empty "${answer}"

discard
