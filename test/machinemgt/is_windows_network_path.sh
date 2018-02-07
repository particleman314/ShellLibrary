#!/usr/bin/env bash

if [ $( is_windows_machine ) -eq "${YES}" ]
then
   answer=$( convert_path --path 'C:\Users' --style mixed )
   assert_equals 'C:/Users' "${answer}"
else
   answer=$( is_windows_network_path )
   assert_failure $?
   assert_false "${answer}"
fi
