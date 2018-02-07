#!/usr/bin/env bash

db_id='API_DB_TEST'
key='myKey'
value='314'

set_rest_api_db --map "${db_id}" --key "${key}" --value "${value}"

key='my2Key'
value='abc123'

set_rest_api_db --map "${db_id}" --key "${key}" --value "${value}"
assert_success $?

key='thirdKey'
value='A space separated text string'

set_rest_api_db --map "${db_id}" --key "${key}" --value "${value}"
assert_success $?

answer="$( get_rest_api_db --map "${db_id}" --key "${key}" )"
assert_success $?
detail "Answer1 = ${answer}"
assert_not_empty "${answer}"
assert_equals "${value}" "${answer}"

delete_rest_api_db
assert_failure $?

delete_rest_api_db --map 'NoMap'
assert_failure $?

delete_rest_api_db --map "${db_id}" --key "${key}"
assert_success $?

answer="$( get_rest_api_db --map "${db_id}" --key "${key}" )"
assert_success $?
assert_empty "${answer}"

answer="$( get_rest_api_db --map "${db_id}" --key 'my2Key' )"
assert_success $?
detail "Answer2 = ${answer}"
assert_not_empty "${answer}"
assert_equals 'abc123' "${answer}"

delete_rest_api_db --map "${db_id}"
answer="$( get_rest_api_db --map "${db_id}" --key 'myKey' )"
assert_success $?
assert_empty "${answer}"
