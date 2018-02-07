#!/usr/bin/env bash

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/cof.test"

schedule_for_demolition "${tmpfile}"

result=$( make_output_file )
assert_not_empty "${result}"
assert_match 'output.' "${result}"
assert_is_file "${result}"

channel=$( find_output_channel --file "${result}" )
assert_not_empty "${channel}"

copy_output_file
assert_failure $?

copy_output_file --channel "${channel}"
assert_failure $?

copy_output_file --file "${result}"
assert_failure $?

copy_output_file --channel "${channel}" --file "${tmpfile}"
assert_success $?
assert_is_file "${tmpfile}"

__cleanup_filemgr
