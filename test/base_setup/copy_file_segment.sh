#!/bin/sh

calc_md5()
{
  printf "%s\n" $( \md5sum "$1" | \cut -f 1 -d ' ' )
}

samplefile='sample_file.txt'
outputfile="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/sample_selection.txt"

filelines=$( __get_line_count "${samplefile}" )
assert_is_file "${samplefile}"

schedule_for_demolition "${outputfile}"

answer="${filelines}"
assert_not_equals 0 "${answer}"

copy_file_segment --filename "${samplefile}" -b 0 -e 0 --outputfile "${outputfile}"
assert_success $?
assert_is_file "${outputfile}"

\which 'md5sum' >/dev/null 2>&1
if [ $? -eq 0 ]
then
  md5_1=$( calc_md5 "${outputfile}" )
  md5_2=$( calc_md5 "${samplefile}" )

  assert_equals "${md5_1}" "${md5_2}"
else
  detail "Unable to test with md5 checksums since 'md5sum' executable not found"
fi
copy_file_segment --filename "${samplefile}" -b 10 -e 9 --outputfile "${outputfile}"
assert_success $?
assert_equals 2 $( __get_line_count "${outputfile}" )

bl=23
el=39
copy_file_segment --filename "${samplefile}" -b ${bl} -e ${el} --outputfile "${outputfile}"
assert_success $?
assert_is_file "${outputfile}"

assert_equals $(( el - bl + 1 )) $( __get_line_count "${outputfile}" )

copy_file_segment --filename "${samplefile}" -b $(( filelines + 1 )) -e 0 --outputfile "${outputfile}"
assert_success $?
assert_equals 1 $( __get_line_count "${outputfile}" )
