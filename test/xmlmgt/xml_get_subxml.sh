#!/bin/sh

. "${SLCF_SHELL_TOP}/lib/file_assertions.sh"
assert_success $?

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1'

subxml=$( xml_get_subxml )
assert_failure $?

subxml=$( xml_get_subxml --xmlfile "${TEST_XML}" --xpath "${fieldpath}" )
assert_success $?
assert_not_empty "${subxml}"
assert_is_file "${subxml}"
