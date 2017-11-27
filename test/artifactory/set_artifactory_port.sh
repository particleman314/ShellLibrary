#!/bin/sh

set_artifactory_port
assert_success $?

set_artifactory_port --value '-9'
assert_failure $?

set_artifactory_port --value '99999'
assert_failure $?

set_artifactory_port --value '555'
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'port' )"
assert_success $?
assert_equals "${answer}" '555'
