#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

answer="$( ini_remove_section )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_remove_section --inifile "${TEST_INI_FILE}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( ini_remove_section --inifile "NoIniSections.txt" --section )"
assert_failure $?
assert_empty "${answer}"

proper_testfile="${TEST_INI_FILE}.2"
\cp -f "${TEST_INI_FILE}" "${proper_testfile}"
schedule_for_demolition "${proper_testfile}"

answer="$( ini_remove_section --inifile "${proper_testfile}" --section 'git' )"
assert_success $?
assert_not_empty "${answer}"

schedule_for_demolition "${answer}"
detail "New file with removed section (git) : ${answer}"

answer="$( ini_remove_section --inifile "${proper_testfile}" --section 'git' --overwrite --content )"
assert_success $?
assert_not_empty "${answer}"

detail "Content from overwritten file..."
detail "${answer}"
discard
