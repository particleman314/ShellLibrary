#!/usr/bin/env bash

answer=$( print_yes )
assert_success $?
assert_equals "${YES}" "${answer}"
