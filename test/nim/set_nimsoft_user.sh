#!/bin/sh

answer=$( get_nimsoft_user )
assert_success $?
assert_equals "${DEFAULT_NIM_ADMIN}" "${answer}"

set_nimsoft_user
assert_failure $?

set_nimsoft_user 'admin'
assert_success $?

answer=$( get_nimsoft_user )
assert_success $?
assert_equals 'admin' "${answer}"

set_nimsoft_user "${DEFAULT_NIM_ADMIN}"
