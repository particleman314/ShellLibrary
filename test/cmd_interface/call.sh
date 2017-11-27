#!/bin/sh

answer=$( call )
assert_failure $?

### All data should be returned to variable (no file written)
answer=$( call --cmd 'ls -lart' )
assert_success $?
assert_not_empty "${answer}"

detail "${answer}"

outputfile=$( make_output_file )
schedule_for_demolition "${outputfile}"

### All data should be returned to variable (file written with output)
answer=$( call --cmd 'ls -1' --output-file "${outputfile}" --save-output )
assert_success $?

detail "$( \cat "${outputfile}" )"
assert_is_file "${outputfile}"
assert_has_filesize "${outputfile}"

detail "${answer}"
