#!/bin/sh

assert_not_empty "${TEST_XML}"

xml_set_file
assert_failure $?

xml_set_file --xmlfile "${TEST_XML}"
assert_success $?
