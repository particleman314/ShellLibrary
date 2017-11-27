#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

__get_key_from_section
assert_failure $?

__get_key_from_section "${TEST_INI_FILE}"
assert_failure $?

__get_key_from_section "${TEST_INI_FILE}" 'not_present_section'
assert_failure $?

__get_key_from_section "${TEST_INI_FILE}" 'temporary' 'missingkey'
assert_failure $?

answer="$( __get_key_from_section "${TEST_INI_FILE}" 'temporary' 'tmpdir' )"
assert_success $?
assert_not_empty "${answer}"
detail "Key (tmpdir) : ${answer}"

answer="$( __get_key_from_section "${TEST_INI_FILE}" 'git' 'gittmpfile' )"
assert_success $?
assert_not_empty "${answer}"
assert_equals '/tmp/xyz/gitcheck.dat' "${answer}"
detail "Key (gittmpfile) : ${answer}"

discard
