#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

answer=$( xml_get_file )
assert_success $?
assert_empty "${answer}"

xml_set_file --xmlfile "${TEST_XML}"

answer=$( xml_get_file )
assert_success $?
assert_not_empty "${answer}"

xml_unset_file
