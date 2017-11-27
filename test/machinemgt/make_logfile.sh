#!/bin/sh

if [ $( is_windows_machine ) -eq "${YES}" ]
then
  answer=$( convert_path --path 'C:\Users' --style windows )
  assert_equals 'C:\\Users' "${answer}"

else
  answer=$( make_logfile )
  assert_success $?
  [ -n "${answer}" ] && schedule_for_demolition "${answer}"
fi
