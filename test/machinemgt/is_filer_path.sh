#!/usr/bin/env bash

install_filer_file()
{
  . "${SLCF_SHELL_TOP}/test/machinemgt/__setup_filer_paths.sh"
  [ -z "${FILER_FILE}" ] && [ ! -f "${FILER_FILE}" ] && return "${FAIL}"
  return "${PASS}"
}

remove_filer_file()
{
  if [ -n "${FILER_FILE}" ]
  then
    [ -f "${FILER_FILE}" ] && rm -f "${FILER_FILE}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

install_filer_file

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( convert_path --path 'C:\Users' --style windows )
  assert_equals 'C:\\Users' "${answer}"
else
  answer=$( is_filer_path )
  assert_failure $?
  assert_false "${answer}"

  answer=$( is_filer_path --path '/tmp' )
  assert_failure $?
  assert_false "${answer}"

  answer=$( is_filer_path --map-file '/non-existent/file' )
  assert_failure $?
  assert_false "${answer}"

  answer=$( is_filer_path --map-file "${FILER_FILE}" --path '/tmp' )
  assert_success $?
  assert_true "${answer}"
fi

remove_filer_file

