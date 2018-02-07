#!/usr/bin/env bash

function __show_internal_cmd_stats()
{
  detail "LAST_CMD      = $( get_last_cmd )"
  detail "LAST_CMD_CODE = $( get_last_cmd_code )"
  return "${PASS}"
}

temporary_dir="${SUBSYSTEM_TEMPORARY_DIR}"

temporary_file="${temporary_dir}/blah.txt"
schedule_for_demolition "${temporary_file}"

associate_file_to_channel --channel 'TEST' --file "${temporary_file}" --ignore-file-existence
issue_cmd --channel 'TEST' --cmd 'ls -1' --output-file "${temporary_file}" > /dev/null 2>&1

__show_internal_cmd_stats

assert_not_empty "$( get_last_cmd )"
assert_success"$( get_last_cmd_code )"

__reset_cmd_stats
assert_empty "$( get_last_cmd )"
assert_empty "$( get_last_cmd_code )"

__show_internal_cmd_stats
