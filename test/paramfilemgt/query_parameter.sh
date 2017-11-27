#!/bin/sh

query_parameter
assert_failure $?

rsrcdir="${SLCF_SHELL_RESOURCEDIR}/common"
rsrcfile="${rsrcdir}/colors.rc"
rsrcfile2="${rsrcdir}/global_settings.rc"

assert_is_file "${rsrcfile}"
assert_is_file "${rsrcfile2}"

answer=$( query_parameter --file "${rsrcfile}" )
assert_failure $?

answer=$( query_parameter --file "${rsrcfile}" --key 'BG_GREEN' )
assert_success $?
assert_not_empty "${answer}"
assert_equals 42 "${answer}"

answer=$( query_parameter --file "${rsrcfile}" --key 'FG_MAROON' )
assert_failure $?

answer=$( query_parameter --file "${rsrcfile2}" --key 'failed_semaphore' --remove-str _pkg )
assert_success $?
assert_not_empty "${answer}"
assert_equals 'failed' "${answer}"
