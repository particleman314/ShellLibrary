#!/usr/bin/env bash

answer="$( __get_artifact_id )"
assert_success $?
assert_empty "${answer}"

set_rest_api_db --map 'ARTIFACTORY' --key 'last_artifactId' --value 'nimsoft'
assert_success $?

answer="$( __get_artifact_id )"
assert_success $?
assert_equals 'nimsoft' "${answer}"
