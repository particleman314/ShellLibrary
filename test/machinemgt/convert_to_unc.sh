#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path --path 'C:\Users' --style mixed )
   assert_equals 'C:/Users' "${answer}"
else
   answer=$( convert_to_unc )
   assert_failure $?

   answer=$( convert_to_unc --userid klumi01 )
   assert_failure $?

   answer=$( convert_to_unc --path 'C:\Users' )
   assert_success $?
   assert_equals $( escapify 'C:\Users' ) "${answer}"

   answer=$( convert_to_unc --path '/tmp' )
   assert_success $?
   assert_equals '/tmp' "${answer}"
fi
