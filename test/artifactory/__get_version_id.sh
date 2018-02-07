#!/usr/bin/env bash

answer="$( __get_version_id )"
assert_success $?
assert_empty "${answer}"

set_rest_api_db --map 'ARTIFACTORY' --key 'last_versionId' --value '0.988'
assert_success $?

answer="$( __get_version_id )"
assert_success $?
assert_equals '0.988' "${answer}"
