#!/bin/sh

assert_not_empty "${TEST_XML}"

__disable_xml_failure 2
assert_not_equals 0 "${__XML_FAILURE_SUPPRESSION}"

__enable_xml_failure
assert_equals 0 "${__XML_FAILURE_SUPPRESSION}"
