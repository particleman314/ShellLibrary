#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

fieldpath='/base/level2/field1'

answer=$( xml_has_section )
assert_failure $?
assert_false "${answer}"

answer=$( xml_has_section --xmlfile "${TEST_XML}" )
assert_failure $?
assert_false "${answer}"

answer=$( xml_has_section --xpath "${fieldpath}" )
assert_failure $?
assert_false "${answer}"

answer=$( xml_has_section --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_true "${answer}"

fieldpath="/A/B/c"
answer=$( xml_has_section --xmlfile "${TEST_XML}" --xpath "${fieldpath}"  )
assert_success $?
assert_false "${answer}"
