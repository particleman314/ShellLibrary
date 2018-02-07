#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path --path 'C:\Users' --style mixed )
   assert_equals 'C:/Users' "${answer}"
else
   answer=$( find_mount_point )
   assert_failure $?
   assert_empty "${answer}"

   answer=$( find_mount_point --path '/tmp' )
   assert_success $?
   assert_equals '/tmp' "${answer}"
fi
