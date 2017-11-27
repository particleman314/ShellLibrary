#!/bin/sh

assert_is_file "${TEST_INI_FILE}"

if [ $( __get_last_result ) -ne "${PASS}" ]
then
  assert_failure 0
else
  proper_testfile="${TEST_INI_FILE}.2"
  \cp "${TEST_INI_FILE}" "${proper_testfile}"

  ini_add_key
  assert_failure $?

  ini_add_key --inifile "${proper_testfile}"
  assert_failure $?

  ini_add_key --inifile "${proper_testfile}" --section 'non_present_section'
  assert_failure $?

  ini_add_key --inifile "${proper_testfile}" --section 'temporary' --value 'newvalue'
  assert_failure $?

  ini_add_key --inifile "${proper_testfile}" --section 'temporary' --key 'key1' --value 'value1' --overwrite
  assert_success $?

  answer="$( ini_add_key --inifile "${answer}" --section 'test_add' --key 'key2' )"
  assert_success $?

  #APPENDED_INI_FILE="${answer}"

  #answer="$( ini_get_keys --inifile "${APPENDED_INI_FILE}" --section 'test_add' )"
  #assert_success $?
  #assert_not_empty "${answer}"
  #assert_equals 2 "$( __get_word_count "${answer}" )"

  #detail "New section (test_add) :"
  #detail "$( ini_get_section --inifile "${APPENDED_INI_FILE}" --section 'test_add' )"

  discard
fi
