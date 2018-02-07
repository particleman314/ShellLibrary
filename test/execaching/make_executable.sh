#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  check_for_cmd_in_path 'edit'
  assert_success $?
else
  make_executable
  assert_failure $?

  make_executable --exe blah
  assert_failure $?

  make_executable --exe find
  assert_success $?
  assert_not_empty "${find_exe}"
  assert_match 'bin/find' "${find_exe}" 

  make_executable --exe true
  assert_success $?

  make_executable --exe date
  assert_success $?
fi
