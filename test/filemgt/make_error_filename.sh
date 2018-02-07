#!/usr/bin/env bash

answer=$( make_error_filename )
assert_success $?
assert_not_empty "${answer}"
detail "${answer}"

answer=$( make_error_filename --func-name 'IS_COMMENT' )
assert_not_empty "${answer}"
detail "${answer}"

schedule_for_demolition "/tmp/error_handling"

answer=$( make_error_filename --func-name 'WOW' --path "${SUBSYSTEM_TEMPORARY_DIR}" )
assert_not_empty "${answer}"
detail "${answer}"
