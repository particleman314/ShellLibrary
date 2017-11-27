#!/bin/sh

assert_not_empty "${TEST_XML}"

__disable_xml_failure 2
answer=$( xml_validate )
assert_failure $?
assert_equals "${NO}" "${answer}" 

answer=$( xml_validate --xmlfile "${TEST_XML}" )
assert_success $?
assert_equals "${YES}" "${answer}"

__enable_xml_failure
