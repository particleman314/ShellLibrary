#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

__disable_xml_failure 2
xml_check_file
assert_failure $?

xml_check_file --xmlfile "${TEST_XML}"
assert_success $?

xml_check_file --errorcode 10
assert $? 10

__enable_xml_failure
