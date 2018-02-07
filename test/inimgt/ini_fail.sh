#!/usr/bin/env bash

ini_fail
assert_failure $?

ini_fail --errorcode "${PASS}"
assert_success $?

ini_fail --errorcode 5
assert_failure $?

answer="$( ini_fail --msg 'Hello' )"
assert_failure $?
assert_not_empty "${answer}"
assert_equals '[ ERROR ] Hello' "${answer}"
