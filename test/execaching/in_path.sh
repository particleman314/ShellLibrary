#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  check_for_cmd_in_path 'edit'
  assert_success $?
else
  in_path
  assert_false $?

  in_path find
  assert_true $?

  in_path blah /usr/bin
  assert_false $?
fi
