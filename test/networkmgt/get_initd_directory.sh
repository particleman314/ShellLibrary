#!/bin/sh

answer=$( get_initd_directory )
assert_success $?
assert_not_empty "${answer}"
