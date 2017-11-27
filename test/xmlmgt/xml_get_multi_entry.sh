#!/bin/sh

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1/subfield2/subsubfield2/subsubfield2entry'

output=$( xml_get_multi_entry )
assert_failure $?

output=$( xml_get_multi_entry --xmlfile "${TEST_XML}" )
assert_failure $?

output=$( xml_get_multi_entry --xpath "${fieldpath}" )
assert_failure $?

output=$( xml_get_multi_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --field '@attribute1' --field '@attribute2' )
assert_not_empty "${output}"
detail "${output}"
