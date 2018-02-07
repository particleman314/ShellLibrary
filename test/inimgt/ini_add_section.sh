#!/usr/bin/env bash

assert_is_file "${TEST_INI_FILE}"

if [ $( __get_last_result ) -ne "${PASS}" ]
then
  assert_failure 0
else
  proper_testfile="${TEST_INI_FILE}.2"
  \cp "${TEST_INI_FILE}" "${proper_testfile}"

  ini_add_section
  assert_failure $?

  ini_add_section --inifile "${proper_testfile}"
  assert_failure $?

  ### Attempt to add new section already present in INI file...
  answer="$( ini_add_section --inifile "${proper_testfile}" --section 'temporary' )"
  assert_success $?
  assert_not_empty "${answer}"
  assert_equals "${proper_testfile}" "${answer}"
  detail "New File 1 : ${answer}"

  answer="$( ini_add_section --inifile "${proper_testfile}" --section 'non_present_section' )"
  assert_success $?
  assert_is_file "${answer}"
  schedule_for_demolition "${answer}"
  detail "New File 2 : ${answer}"

  total_old_lines=$( __get_line_count "${proper_testfile}" )
  answer="$( ini_add_section --inifile "${proper_testfile}" --section 'non_present_section' --overwrite )"
  assert_success $?
  total_new_lines=$( __get_line_count "${proper_testfile}" )
  assert_not_equals "${total_old_lines}" "${total_new_lines}"

  answer="$( __find_actual_line_for_section "${propet_testfile}" 'non_present_section' )"
  assert_success $?

  [ -f "${proper_testfile}" ] && \rm -f "${proper_testfile}"
fi

