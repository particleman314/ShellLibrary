#!/usr/bin/env bash

answer=$( print_no )
assert_success $?
assert_equals "${NO}" "${answer}"
