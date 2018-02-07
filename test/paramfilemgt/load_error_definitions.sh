#!/usr/bin/env bash

load_error_definitions --file 'global_error_defs.rc' --suppress
assert_success $?
assert_not_empty "${NOT_EXECUTABLE}"
assert_equals 3 "${NOT_EXECUTABLE}"
