#!/bin/sh

assert_not_empty "${TEST_XML}"

__disable_xml_failure 2
assert_equals 1 "${__XML_FAILURE_SUPPRESSION}"

__disable_xml_failure 1
assert_equals 1 "${__XML_FAILURE_SUPPRESSION}"
