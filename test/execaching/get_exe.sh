#!/bin/sh

if [ $( is_windows_machine --no-cygwin ) -eq "${YES}" ]
then
  check_for_cmd_in_path 'edit'
  assert_success $?
  detail "edit command found"
else
  answer=$( get_exe )
  assert_failure $?
  assert_empty "${answer}"

  answer=$( get_exe --path '/usr/bin' )
  assert_failure $?
  assert_empty "${answer}"

  answer=$( get_exe --exename 'find' )
  assert_success $?
  assert_not_empty "${answer}"
  detail "find command : ${answer}"
  
  answer=$( get_exe --exename 'blah' )
  assert_failure $?
  assert_empty "${answer}"
fi