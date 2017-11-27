#!/bin/sh

temporary_dir="${SUBSYSTEM_TEMPORARY_DIR}"

answer=$( get_last_cmd_code )
assert_success $?
assert_not_empty "${answer}"

temporary_file="${temporary_dir}/blah.txt"
schedule_for_demolition "${temporary_file}"

associate_file_to_channel --channel 'TEST' --file "${temporary_file}" --ignore-file-existence
issue_cmd --channel 'TEST' --cmd 'ls -1' --output-file "${temporary_file}" >/dev/null 2>&1

answer=$( get_last_cmd_code )
assert_success $?
assert_not_empty "${answer}"
assert_success "${answer}"

__reset_cmd_stats
