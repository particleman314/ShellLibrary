#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( make_unix_windows_path --path 'C:\Users' --style windows )
else
  answer=$( make_unix_windows_path )
  assert_failure $?

  answer=$( make_unix_windows_path --path '/tmp' )
  assert_success $?
  assert_equals '/tmp' "${answer}"
  
  answer=$( make_unix_windows_path --path '/tmp' --style unix )
  assert_success $?
  assert_equals '/tmp' "${answer}" 
fi
