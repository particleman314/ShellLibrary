#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( convert_path --path 'C:\Users' --style mixed )
  assert_equals 'C:/Users' "${answer}"
else
  assert_empty "${SCRIPT_PATH}"
  answer=$( get_script_path )
  assert_success $?
  assert_not_empty "${answer}"
  
  detail "${answer}"
  assert_equals "${SHELL_ROOT_DIR}/TEST" "${answer}"
fi
