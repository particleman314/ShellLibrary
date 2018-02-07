#!/usr/bin/env bash

set_artifactory_protocol
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'protocol' )"
assert_success $?
assert_equals "${answer}" 'http'

set_artifactory_protocol --value 'sftp'
assert_success $?

answer="$( get_rest_api_db --map 'ARTIFACTORY' --key 'protocol' )"
assert_success $?
assert_equals "${answer}" 'sftp'
