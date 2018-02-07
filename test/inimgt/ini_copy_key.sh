#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

### no arguments
answer="$( ini_copy_key )"
assert_failure $?
assert_empty "${answer}"

### no section provided
answer="$( ini_copy_key --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

### no ini file provided
answer="$( ini_copy_key --inifile --section 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_key --inifile 'NoIniSections.txt' --oldsection 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_key --inifile "${TEST_IN_FILE}" --newsection 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_key --inifile "${TEST_IN_FILE}" --newsection 'test' --oldkey 'blah' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_key --inifile "${TEST_IN_FILE}" --newsection 'test' --newkey 'dude' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_key --inifile "${TEST_INI_FILE}" --oldsection 'git' --oldkey 'gittoken' --newkey 'gittoken_2' )"
assert_success $?
assert_not_empty "${answer}"
detail "New file : ${answer}"

expected_key="$( ini_get_key_from_section --inifile "${answer}" --section 'git' --key 'gittoken_2' )"
assert_success $?
assert_not_empty "${expected_key}"
detail "Copied key ( gittoken --> gittoken_2 ) : ${expected_key}"

discard
