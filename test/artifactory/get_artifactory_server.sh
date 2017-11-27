#!/bin/sh

answer="$( get_artifactory_server )"
assert_success $?
assert_empty "${answer}"

set_artifactory_server --value 'artifactory.dev.fco'
assert_success $?

answer="$( get_artifactory_server )"
assert_success $?
assert_equals "${answer}" 'artifactory.dev.fco'
