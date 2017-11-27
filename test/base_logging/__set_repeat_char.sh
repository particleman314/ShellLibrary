#!/bin/sh

answer=$( __get_repeat_char )
assert_success $?
assert_equals '=' "${answer}"

new_char='|'

__set_repeat_char "${new_char}"

answer=$( __get_repeat_char )
assert_success $?
assert_equals "${new_char}" "${answer}"
