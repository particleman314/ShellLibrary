#!/bin/sh

convert_pattern
assert_failure $?

tempdir="${SUBSYSTEM_TEMPORARY_DIR}"
mkdir -p "${tempdir}/filemgt"

outputfile="${tempdir}/filemgt/myfile.txt"
schedule_for_demolition "${tempdir}/filemgt"

matching_files=$( collect_files --outfile "${outputfile}" --pattern '*.sh' --keepfile )

detail "Files : ${matching_files}"
convert_pattern --file "${outputfile}"
assert_failure $?

convert_pattern --file "${outputfile}" --old-patt '.sh'
assert_success $?
assert_is_file "${outputfile}"

force_skip

\grep -q '.sh' "${outputfile}"
assert_success $?

printf "%s\n" "${matching_files}" > "${outputfile}"
convert_pattern --file "${outputfile}" --old-patt '.sh' --new-patt '.abc' --backup
assert_success $?
assert_is_file "${outputfile}"

grep -q '.abc' "${outputfile}"
assert_success $?

printf "%s\n" "${matching_files}" > "${outputfile}"
convert_pattern --file "${outputfile}" --old-patt '.sh' --new-patt '.abc' --backup --global
assert_success $? 
assert_is_file "${outputfile}"
assert_is_file "${outputfile}.bak"
schedule_for_demolition "${outputfile}.bak"

grep -q '.abc' "${outputfile}"
assert_success $?

clear_force_skip
