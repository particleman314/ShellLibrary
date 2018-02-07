#!/usr/bin/env bash

set_artifactory_user
assert_failure $?

set_artifactory_user --value 'klumi01'
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'user' )"
assert_success $?
assert_equals "${answer}" 'klumi01'
