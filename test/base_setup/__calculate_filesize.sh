#!/bin/sh

answer=$( __calculate_filesize )
assert_failure $?
assert_equals 0 "${answer}"

answer=$( __calculate_filesize "${SLCF_SHELL_FUNCTIONDIR}/constants.sh" )
assert_success $?
detail "File size : ${answer}"
assert_greater "${answer}" 0
