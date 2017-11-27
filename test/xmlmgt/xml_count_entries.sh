#!/bin/sh

assert_not_empty "${TEST_XML}"

__disable_xml_failure

fieldpath='/base/level2/field1/subfield2/subsubfield2'

answer=$( xml_count_entries )
assert_failure $?
assert_false "${answer}"

answer=$( xml_count_entries --xmlfile "${TEST_XML}" )
assert_failure $?
assert_equals "${answer}" 0

answer=$( xml_count_entries --xpath "${fieldpath}" )
assert_failure $?
assert_equals "${answer}" 0

answer=$( xml_count_entries --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_equals "${answer}" 2

fieldpath="/base/level2/field1/subfield2/subsubfield1"
answer=$( xml_count_entries --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_equals "${answer}" 1

fieldpath="/base/level2/field1/blah"
answer=$( xml_count_entries --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_equals "${answer}" 0
