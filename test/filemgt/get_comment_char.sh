#!/usr/bin/env bash

answer=$( get_comment_char )
assert_success $?
assert_equals '#' "${answer}"

set_comment_char '//'

answer=$( get_comment_char )
assert_success $?
assert_equals '//' "${answer}"

set_comment_char '#'
