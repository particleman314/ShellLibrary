#!/bin/sh

answer=$( collect_files )
assert_success $?
assert_not_empty "${answer}"

tempdir="${SUBSYSTEM_TEMPORARY_DIR}"
mkdir -p "${tempdir}/filemgt"

outputfile="${tempdir}/myfile.txt"
schedule_for_demolition "${outputfile}"

answer=$( collect_files --outfile "${outputfile}" )
assert_success $?
assert_not_empty "${answer}"

answer=$( collect_files --outfile "${outputfile}" --pattern '*.sh' )
assert_success $?
assert_not_empty "${answer}"
assert_comparison --comparison 'greater' $( echo "${answer}" | wc -w ) 1

answer=$( collect_files --outfile "${outputfile}" --pattern '*.sh' --keepfile )
assert_success $?
assert_not_empty "${answer}"
assert_is_file "${outputfile}"
