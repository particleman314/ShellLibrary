#!/usr/bin/env bash

OLD_WAREHOUSE='10.238.40.43'

answer="$( __write_connection_dialog )"
assert_failure $?
assert_empty "${answer}"

answer="$( __write_connection_dialog --ip "${OLD_WAREHOUSE}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( __write_connection_dialog --remote-user 'root' )"
assert_failure $?
assert_empty "${answer}"

answer="$( __write_connection_dialog --ip "${OLD_WAREHOUSE}" --remote-user 'any_user' )"
assert_success $?
assert_not_empty "${answer}"
assert_is_file "${answer}"
assert_has_filesize "${answer}"

detail "${answer}"
schedule_for_demolition "${answer}"
