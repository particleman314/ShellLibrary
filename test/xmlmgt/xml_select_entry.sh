#!/bin/sh

assert_not_empty "${TEST_XML}"

__disable_xml_failure

fieldpath='/base/level2/field1/subfield2/subsubfield2'

answer=$( xml_select_entry )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_select_entry --xmlfile "${TEST_XML}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_select_entry --xpath "${fieldpath}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_select_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_select_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --id 1 )
assert_success $?
assert_not_empty "${answer}"

answer=$( xml_select_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --id 10 )
assert_failure $?
assert_empty "${answer}"

fieldpath="/base/level2/field1/blah"
answer=$( xml_select_entry --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --id 1 )
assert_failure $?
assert_empty "${answer}"
