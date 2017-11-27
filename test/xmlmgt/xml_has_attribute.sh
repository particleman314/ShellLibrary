#!/bin/sh

assert_not_empty "${TEST_XML}"

fieldpath='/base/level1/field2'
attrname='attribute1'

answer=$( xml_has_attribute )
assert_success $?
assert_false "${answer}"

answer=$( xml_has_attribute --xmlfile "${TEST_XML}" )
assert_success $?
assert_false "${answer}"

answer=$( xml_has_attribute --xpath "${fieldpath}" )
assert_success $?
assert_false "${answer}"

answer=$( xml_has_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_false "${answer}"

answer=$( xml_has_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --attr "${attrname}" )
assert_success $?
assert_true "${answer}"

fieldpath='/base/level2/field1'
answer=$( xml_has_attribute --xmlfile "${TEST_XML}" --xpath "${fieldpath}" --attr "${attrname}" )
assert_success $?
assert_false "${answer}"

detail 'Completed'