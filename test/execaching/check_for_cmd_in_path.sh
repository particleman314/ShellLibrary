#!/bin/sh

check_for_cmd_in_path ''
assert_success $?

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  check_for_cmd_in_path 'edit'
  assert_success $?
else
  check_for_cmd_in_path 'find'
  assert_success $?
  
  check_for_cmd_in_path 'blah'
  assert_failure $?
fi
