#!/usr/bin/env bash

file_match="${SLCF_SHELL_FUNCTIONDIR}/assertions.sh"

answer=$( get_file_line_length )
assert_failure $?
assert_equals 0 "${answer}"

[ ! -f "${file_match}" ] && force_skip

answer=$( get_file_line_length "${file_match}" )
assert_success $?
assert_not_equals 0 "${answer}"

[ -n "${answer}" ] && detail "Line length for <${file_match}> is ${answer}"

clear_force_skip
