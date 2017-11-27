#!/bin/sh

OLD_WAREHOUSE='10.238.40.43'

answer="$( __run_passwordless_access_check )"
assert_failure $?
assert_false "${answer}"

answer="$( __run_passwordless_access_check --user 'root' )"
assert_failure $?
assert_false "${answer}"

answer="$( __run_passwordless_access_check --host "${OLD_WAREHOUSE}" )"
assert_failure $?
assert_false "${answer}"

answer="$( __run_passwordless_access_check --host "${OLD_WAREHOUSE}" --user 'root' )"
assert_success $?
assert_not_empty "${answer}"
assert_false "${answer}"

detail "${answer}"
