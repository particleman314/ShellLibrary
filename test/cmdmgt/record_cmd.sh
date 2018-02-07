#!/usr/bin/env bash

temporary_dir="${SUBSYSTEM_TEMPORARY_DIR}"

record_cmd
assert_failure $?

record_cmd --channel 'ONE' --channel 'TWO'
assert_failure $?

temporary_file="$( make_output_file --prefix 'CMDMGT' --directory "${temporary_dir}" )"
assert_success $?
if [ -n "${temporary_file}" ]
then
  assert_is_file "${temporary_file}"
  schedule_for_demolition "${temporary_file}"

  record_cmd --filename "${temporary_file}" --cmd 'ls -1'
  assert_success $?
  assert_empty "$( get_last_cmd_code )"
fi

__reset_cmd_stats
