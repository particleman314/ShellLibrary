#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

answer="$( ini_remove_key_from_section )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_remove_key_from_section --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_remove_key_from_section --inifile "NoIniSections.txt" --section --key 'git' )"
assert_failure $?
assert_empty "${answer}"

proper_testfile="${TEST_INI_FILE}.2"
\cp "${TEST_INI_FILE}" "${proper_testfile}"
schedule_for_demolition "${proper_testfile}"

answer="$( ini_remove_key_from_section --inifile "${proper_testfile}" --section 'git' --key 'gittoken' )"
assert_success $?
assert_not_empty "${answer}"

schedule_for_demolition "${answer}"
detail "New file with removed key (gittoken) : ${answer}"

answer="$( ini_remove_key_from_section --inifile "${proper_testfile}" --section 'temporary' --key 'tmpdir' --overwrite --content )"
assert_success $?
assert_not_empty "${answer}"

detail "Content from overwritten file..."
detail "${answer}"
discard
