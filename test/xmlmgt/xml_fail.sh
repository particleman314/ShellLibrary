#!/usr/bin/env bash

assert_not_empty "${TEST_XML}"

answer=$( xml_fail --message "Sample XML Failure" )
assert_failure $?
assert_not_empty "${answer}"

answer=$( xml_fail --message "Sample XML Failure with personalized errorcode" --errorcode 5 )
RC=$?
assert_failure "${RC}"
assert "${RC}" 5
assert_not_empty "${answer}"

detail "${answer}"
