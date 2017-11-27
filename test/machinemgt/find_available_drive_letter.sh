#!/bin/sh

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path --path 'C:\Users' --style mixed )
   assert_equals 'C:/Users' "${answer}"
else
   answer=$( find_available_drive_letter )
   assert_failure $?
   assert_empty "${answer}"
fi
