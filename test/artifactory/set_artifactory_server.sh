#!/usr/bin/env bash

set_artifactory_server
assert_failure $?

set_artifactory_server --value 'artifactory.dev.fco'
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'server' )"
assert_success $?
assert_equals "${answer}" 'artifactory.dev.fco'
