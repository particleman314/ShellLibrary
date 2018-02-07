#!/usr/bin/env bash

set_artifactory_password
assert_failure $?

set_artifactory_password --value "$( get_password_prefix )dDNzdGk5$( get_password_suffix )"
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'password' )"
assert_success $?
assert_equals "${answer}" "$( get_password_prefix )dDNzdGk5$( get_password_suffix )"
