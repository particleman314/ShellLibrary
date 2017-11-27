#!/bin/sh

answer="$( __get_group_id )"
assert_success $?
assert_empty "${answer}"

set_rest_api_db --map 'ARTIFACTORY' --key 'last_groupId' --value 'com.ca'
assert_success $?

answer="$( __get_group_id )"
assert_success $?
assert_equals 'com.ca' "${answer}"
