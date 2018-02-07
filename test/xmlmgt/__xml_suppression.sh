#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

__xml_suppression
assert_success $?

__disable_xml_failure "${YES}"
answer=$( __xml_suppression "This is not an error in XML" )
assert_success $?
assert_empty "${answer}"

__enable_xml_failure "${YES}"
answer=$( __xml_suppression "This is an error in XML" )
assert_success $?
assert_not_empty "${answer}"

