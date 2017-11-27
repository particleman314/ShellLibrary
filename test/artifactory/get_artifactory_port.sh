#!/bin/sh

answer="$( get_artifactory_port )"
assert_success $?
assert_empty "${answer}"

set_artifactory_port --value '555'
assert_success $?

answer="$( get_artifactory_port )"
assert_success $?
assert_equals "${answer}" '555'
