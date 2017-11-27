#!/bin/sh

display_output()
{
  if [ -n "${SLCF_DETAIL}" ]
  then
    [ -n "$1" ] && detail "$1"
  else
    [ -n "$1" ] && printf "SAMPLE OUTPUT --> %s\n" "$1"
  fi
}

bypass_recording="--disable-filename"

answer=$( __record_fail ${bypass_recording} )
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test' )
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test_2' --aid 4 --tid 9 )
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test_2' --aid 8 --tid 3 --expect 1 --actual 6 )
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test_2' --aid 1 --tid 2 --expect 5 --actual 5 )
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test_3' --aid 66 --tid 10 --expect 5 --actual 5 --cause 'Misconfigured_test')
display_output "${answer}"

answer=$( __record_fail ${bypass_recording} --testname 'Sample_Test_3' --tid 10 --expect 5 --actual 5 --title 'Personalized_Title_for_Failure' )
display_output "${answer}"

__reset_assertion_counters
