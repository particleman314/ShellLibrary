#!/bin/sh

assert_not_empty "${__DEFAULT_PASSWORD_PREFIX}"
assert_not_empty "${__PASSWORD_PREFIX}"

current_pp=$( get_password_prefix )

set_password_prefix 'XYZ'
assert_not_empty "${__PASSWORD_PREFIX}"
assert_equals 'XYZ' "${__PASSWORD_PREFIX}"

set_password_prefix
assert_empty "${__PASSWORD_PREFIX}"

set_password_prefix "${current_pp}"