#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

answer="$( ini_get_keys )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_keys --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_keys --inifile 'NoIniSections.txt' --section 'git' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_keys --inifile "${TEST_INI_FILE}" --section 'git' )"
assert_success $?
assert_non_empty "${answer}"

expected_number_keys=$( __get_word_count "${answer}" )
assert_equals 6 "${expected_number_keys}"

detail "Git Section Keys : "
detail "${answer}"

discard
