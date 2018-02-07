#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  check_for_cmd_in_path 'edit'
  assert_success $?
else
  manage_executables find true
  assert_success $?

  detail "find exe --> ${find_exe}"
  detail "true exe --> ${true_exe}"

  assert_not_empty "${find_exe}"
  assert_not_empty "${true_exe}"

  manage_executables --suppress non_existent
  assert_empty "${non_existent_exe}"
fi
