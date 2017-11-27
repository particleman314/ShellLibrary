#!/bin/sh

answer=$( print_yes )
assert_success $?
assert_equals "${YES}" "${answer}"
