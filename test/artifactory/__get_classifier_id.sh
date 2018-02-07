#!/usr/bin/env bash

answer="$( __get_classifier_id )"
assert_success $?
assert_empty "${answer}"

set_rest_api_db --map 'ARTIFACTORY' --key 'last_classifier' --value 'tar'
assert_success $?

answer="$( __get_classifier_id )"
assert_success $?
assert_equals 'tar' "${answer}"
