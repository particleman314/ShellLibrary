#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path_for_machine --path 'C:\Users' --style windows )
else
   answer=$( convert_path_for_machine )
   assert_failure $?

   answer=$( convert_path_for_machine --path '/tmp' )
   assert_success $?
   assert_equals '/tmp' "${answer}"
  
   answer=$( convert_path_for_machine --path '/tmp' --style windows )
   assert_success $?
   assert_empty "${answer}"
fi
