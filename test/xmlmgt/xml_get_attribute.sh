#!/bin/sh

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1/subfield2/subsubfield3/subsubfield3entry'

answer=$( xml_get_attribute )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_attribute --xmlfile "${TEST_XML}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_attribute --xpath "${fieldpath}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --attr 'attribute2' )
assert_success $?
assert_equals "${answer}" 4

fieldpath="/base/level2/field1/subfield2/subsubfield1/subsubfieldentry"
answer=$( xml_get_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --attr 'attribute2' )
assert_success $?
assert_empty "${answer}"

fieldpath="/base/level2/field1/blah"
answer=$( xml_get_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --attr 'attribute2' )
assert_success $?
assert_empty "${answer}"
