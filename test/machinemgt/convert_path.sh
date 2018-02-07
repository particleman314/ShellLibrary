#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path --path 'C:\Users' --style windows )
   assert_equals 'C:\\Users' "${answer}"

   answer=$( convert_path --path 'C:\Users' --style unix )
   assert_match 'cygdrive' "${answer}"
   assert_match 'Users' "${answer}"

   answer=$( convert_path --path 'C:\Users' --style mixed )
   assert_equals 'C:/Users' "${answer}"
else
   answer=$( convert_path --path '/tmp' --style windows )
   assert_equals '/tmp' "${answer}"

   answer=$( convert_path --path '/tmp' --style unix )
   assert_equals '/tmp' "${answer}"

   answer=$( convert_path --path '/opt/check/this/directory' --style mixed )
   assert_equals '/opt/check/this/directory' "${answer}"
fi
