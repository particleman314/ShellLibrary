#!/usr/bin/env bash

assert_not_empty "${__DEFAULT_PASSWORD_SUFFIX}"
assert_not_empty "${__PASSWORD_SUFFIX}"

current_ps=$( get_password_suffix )

set_password_suffix 'XYZ'
assert_not_empty "${__PASSWORD_SUFFIX}"
assert_equals 'XYZ' "${__PASSWORD_SUFFIX}"

set_password_suffix
assert_empty "${__PASSWORD_SUFFIX}"

set_password_suffix "${current_ps}"
