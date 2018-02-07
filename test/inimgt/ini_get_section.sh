#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

### no arguments
answer="$( ini_get_section )"
assert_failure $?
assert_empty "${answer}"

### no section provided
answer="$( ini_get_section --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

### no ini file provided
answer="$( ini_get_section --inifile --section 'test' )"
assert_failure $?
assert_empty "${answer}"

### improper file provided
answer="$( ini_get_section --inifile 'NoIniSections.txt' --section 'test' )"
assert_failure $?
assert_empty "${answer}"

### missing section provided
answer="$( ini_get_section --inifile "${TEST_INI_FILE}" --section '' )"
assert_failure $?
assert_empty "${answer}"

### return extracted filename for specific subsection
answer="$( ini_get_section --inifile "${TEST_INI_FILE}" --section 'git' )"
assert_success $?
assert_not_empty "${answer}"
assert_is_file "${answer}"

### return content from extracted specific subsection
answer="$( ini_get_section --inifile "${TEST_INI_FILE}" --section 'git' --content )"
assert_success $?
assert_not_empty "${answer}"

detail "Git Section Data : "
detail "${answer}"

discard
