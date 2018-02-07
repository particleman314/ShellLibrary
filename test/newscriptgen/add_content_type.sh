#!/usr/bin/env bash

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/scriptgen.txt"
\touch "${tmpfile}"

assert_not_empty "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

add_content_type
assert_failure $?

add_content_type --content 'blah'
assert_failure $?

add_content_type --file "${tmpfile}" --content 'disclaimer'
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"
\touch "${tmpfile}"
assert_has_filesize --modify "${__NEGATIVE}" "${tmpfile}"

add_content_type --file "${tmpfile}" --content 'header'
assert_success $?
assert_has_filesize "${tmpfile}"

\rm -f "${tmpfile}"
