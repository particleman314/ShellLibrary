#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1/subfield2/subsubfield1'

answer=$( xml_get_text )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_text --xmlfile "${TEST_XML}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_text --xpath "${fieldpath}" )
assert_failure $?
assert_empty "${answer}"

answer=$( xml_get_text --xmlfile "${TEST_XML}" --xpath "${fieldpath}" )
assert_success $?
assert_equals "${answer}" 'develop/bus_2015q4'

fieldpath="/base/level2/field1/subfield2/subsubfield1/subsubfieldentry"
answer=$( xml_get_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" )
assert_failure $?
assert_empty "${answer}"

fieldpath="/base/level2/field1/blah"
answer=$( xml_get_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}")
assert_failure $?
assert_empty "${answer}"
