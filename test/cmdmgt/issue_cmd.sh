#!/bin/sh

temporary_dir="${SUBSYSTEM_TEMPORARY_DIR}"

issue_cmd
assert_failure $?

issue_cmd --channel 'ONE' --channel 'TWO'
assert_failure $?

temporary_file="${temporary_dir}/blah.txt"
schedule_for_demolition "${temporary_file}"

associate_file_to_channel --channel 'TEST' --file "${temporary_file}" --ignore-file-existence
issue_cmd --channel 'TEST' --output-file "${temporary_file}"
assert_failure $?

issue_cmd --channel 'TEST' --cmd 'ls -1' --output-file "${temporary_file}"
assert_success $?
assert_is_file "${temporary_file}"
assert_has_filesize "${temporary_file}"

answer="$( issue_cmd --channel 'TEST' --cmd 'ls -1' --save-output )"
detail "ANSWER = ${answer}"
assert_success $?
assert_not_empty "${answer}"

__reset_cmd_stats
