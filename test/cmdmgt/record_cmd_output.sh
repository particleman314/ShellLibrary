#!/usr/bin/env bash

temporary_dir="${SUBSYSTEM_TEMPORARY_DIR}"

record_cmd_output
assert_success $?

answer="$( record_cmd_output --save-output )"
assert_success $?
assert_not_empty "${answer}"
assert_is_file "${answer}"

schedule_for_demolition "${answer}"

temporary_file="$( make_output_file --prefix 'CMDMGT' )"
assert_success $?
if [ -n "${temporary_file}" ]
then
  assert_is_file "${temporary_file}"
  schedule_for_demolition "${temporary_file}"
  answer="$( record_cmd_output --save-output --channel 'CMDMGT' )"
  assert_success $?
  assert_not_empty "${answer}"
  assert_is_file "${answer}"

  schedule_for_demolition "${answer}"
fi

__reset_cmd_stats
