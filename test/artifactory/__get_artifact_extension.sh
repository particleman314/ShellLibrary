#!/usr/bin/env bash

answer="$( __get_artifact_extension )"
assert_success $?
assert_empty "${answer}"

set_rest_api_db --map 'ARTIFACTORY' --key 'last_artifact_extension' --value 'zip'
assert_success $?

answer="$( __get_artifact_extension )"
assert_success $?
assert_equals 'zip' "${answer}"
