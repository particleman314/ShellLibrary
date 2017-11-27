#!/bin/sh

answer=$( print_no )
assert_success $?
assert_equals "${NO}" "${answer}"
