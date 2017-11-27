#!/bin/sh

detail "Before :"
detail "   PATH --> ${PATH}"

add_to_envvar
assert_success $?

add_to_envvar --data 'Hello' --envvar 'World'
assert_not_empty "${World}"
assert_equals 'Hello' "${World}"

envpath="${PATH}"
assert_not_empty "${envpath}"
add_to_envvar --data "${SLCF_SHELL_TOP}/bin"
assert_success $?
assert_not_equals "${envpath}" "${PATH}"

add_to_envvar --data "${SLCF_SHELL_TOP}/bin" --location append
assert_success $?
assert_not_equals "${envpath}" "${PATH}"

detail "After :"
detail "   PATH --> ${PATH}"
