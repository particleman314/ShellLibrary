#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

### no arguments
answer="$( ini_copy_section )"
assert_failure $?
assert_empty "${answer}"

### no section provided
answer="$( ini_copy_section --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

### no ini file provided
answer="$( ini_copy_section --inifile --section 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_section --inifile 'NoIniSections.txt' --oldsection 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_section --inifile "${TEST_IN_FILE}" --newsection 'test' )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_copy_section --inifile "${TEST_INI_FILE}" --oldsection 'git' --newsection 'git_v2' )"
assert_success $?
assert_not_empty "${answer}"

expected_section="$( ini_get_section --inifile "${answer}" --section 'git_v2' --content )"
assert_success $?
assert_not_empty "${expected_section}"

discard
