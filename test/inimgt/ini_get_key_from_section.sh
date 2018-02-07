#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

answer="$( ini_get_key_from_section )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_key_from_section --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_key_from_section --inifile "NoIniSections.txt" --section 'git' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_key_from_section --inifile "${TEST_INI_FILE}" --section 'git' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_get_key_from_section --inifile "${TEST_INI_FILE}" --section 'git' --key 'gittoken' )"
assert_success $?
assert_not_empty "${answer}"

detail "Key (git) : ${answer}"

answer="$( ini_get_key_from_section --inifile "${TEST_INI_FILE}" --section 'git' --key 'unknown_key' )"
assert_failure $?
assert_empty "${answer}"

discard
