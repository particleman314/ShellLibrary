#!/bin/sh

answer=$( get_nimsoft_user_pswd )
assert_success $?
assert_equals "${DEFAULT_NIM_ADMIN_PWD}" "${answer}"

set_nimsoft_user_pswd
assert_failure $?

set_nimsoft_user_pswd 'SUPi9ro0t'
assert_success $?

answer=$( get_nimsoft_user_pswd )
assert_success $?
assert_equals 'SUPi9ro0t' "${answer}"
