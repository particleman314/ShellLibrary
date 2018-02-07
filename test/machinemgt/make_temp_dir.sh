#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( convert_path --path 'C:\Users' --style windows )
  assert_equals 'C:\\Users' "${answer}"

else
  answer=$( make_temp_dir )
  assert_success $?
  assert_not_empty "${answer}"
  assert_is_directory "${answer}"

  detail "Temporary Directory --> ${answer}"
  [ -n "${answer}" ] && schedule_for_demolition "${answer}"

  answer=$( make_temp_dir --directory "${SUBSYSTEM_TEMPORARY_DIR}/MACHINE_TEMP_DIR" )
  assert_success $?
  assert_not_empty "${answer}"
  assert_is_directory "${answer}"

  detail "Temporary Directory --> ${answer}"
  [ -n "${answer}" ] && schedule_for_demolition "${answer}"
fi
