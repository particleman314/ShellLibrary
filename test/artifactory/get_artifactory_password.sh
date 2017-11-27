#!/bin/sh

answer="$( get_artifactory_password )"
assert_success $?
assert_empty "${answer}"

set_artifactory_password --value "$( get_password_prefix )dDNzdGk5$( get_password_suffix )"
assert_success $?

answer="$( get_artifactory_password )"
assert_success $?
assert_equals "${answer}" 't3sti9'
