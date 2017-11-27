#!/bin/sh

detail "Starting test for method : $1"

answer=$( which_linux_variety_to_use )
assert_success $?
assert_not_empty "${answer}"

detail "Machine Type : ${answer}"

detail "Ending test for method : $1"
