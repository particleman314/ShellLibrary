#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1'
field='subfield1'

output=$( xml_get_single_entry )
assert_failure $?

output=$( xml_get_single_entry --xmlfile "${TEST_XML}" )
assert_failure $?

output=$( xml_get_single_entry --field "${fieldpath}" )
assert_failure $?

output=$( xml_get_single_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --field "${field}" )
assert_not_empty "${output}"
assert_equals 'http://teamcity.dev.fco:8111' "${output}"
