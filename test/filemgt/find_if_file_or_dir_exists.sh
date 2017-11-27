#!/bin/sh

find_if_file_or_dir_exists
assert_failure $?

find_if_file_or_dir_exists --file "${SLCF_SHELL_TOP}/lib/filemgt.sh"
assert_success $?

find_if_file_or_dir_exists --directory "${SUBSYSTEM_TEMPORARY_DIR}"
assert_success $?

# Needs to test for remote access of file/director
