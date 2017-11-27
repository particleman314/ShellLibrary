#!/bin/sh

assert_not_empty "${OSVARIETY}"

iswin=$( is_windows_machine )
assert_success $?
assert_not_empty "${iswin}"
