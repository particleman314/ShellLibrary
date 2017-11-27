#!/bin/sh

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( convert_path --path 'C:\Users' --style windows )
  assert_equals 'C:\\Users' "${answer}"
else
  answer=$( is_abs_path )
  assert_success $?
  assert_false "${answer}"

  answer=$( is_abs_path --path "${SLCF_SHELL_TOP}" )
  assert_success $?
  assert_true "${answer}"

  answer=$( is_abs_path --path 'TEST' )
  assert_success $?
  assert_false "${answer}"
fi
