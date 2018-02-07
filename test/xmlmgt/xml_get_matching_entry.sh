#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

match='attribute1=3'
fieldpath='/base/level2/field1/subfield2/subsubfield2/subsubfield2entry/listentry'
field='.'

answer=$( xml_get_matching_entry )
assert_failure $?

answer=$( xml_get_matching_entry --xmlfile "${TEST_XML}" )
assert_failure $?

answer=$( xml_get_matching_entry --xpath "${fieldpath}" )
assert_failure $?

answer=$( xml_get_matching_entry --field "${field}" )
assert_failure $?

answer=$( xml_get_matching_entry --match "${match}" )
assert_failure $?

answer=$( xml_get_matching_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --match 'attribute1=3' --field '.' )
assert "${answer}" CC

answer=$( xml_get_matching_entry --xmlfile "${TEST_XML}" --xpath '/base/level2/field1/subfield2/subsubfield2/subsubfield2entry/listentry' --match 'attribute1=10' --field '.' )
assert_empty "${answer}"
