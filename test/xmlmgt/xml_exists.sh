#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

__disable_xml_failure 2

xml_exists
assert_false $?

xml_exists --xmlfile "${TEST_XML}"
assert_false $?

xml_exists --xmlfile "${TEST_XML}" --xpath '/base/level1'
assert_true $?

xml_exists --xmlfile "${TEST_XML}" --xpath '/base/level9'
assert_false $?

__enable_xml_failure
