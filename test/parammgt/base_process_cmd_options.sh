#!/bin/sh

answer=$( base_process_cmd_options )
assert_success $?
assert_not_empty "${answer}"

detail "Basic commands : ${answer}"
