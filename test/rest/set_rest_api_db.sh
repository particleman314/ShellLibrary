#!/bin/sh

db_id='API_DB_TEST'
key='myKey'
value='314'

set_rest_api_db
assert_failure $?

set_rest_api_db --map "${db_id}"
assert_failure $?

set_rest_api_db --key "${key}"
assert_failure $?

set_rest_api_db --value "${value}"
assert_failure $?

set_rest_api_db --map "${db_id}" --key "${key}"
assert_failure $?

set_rest_api_db --map "${db_id}" --key "${key}" --value "${value}"
assert_success $?

answer="$( get_rest_api_db --map "${db_id}" --key "${key}" )"
assert_success $?
detail "Answer = ${answer}"
assert_not_empty "${answer}"
assert_equals "${value}" "${answer}"

key='my2Key'
value='abc123'

set_rest_api_db --map "${db_id}" --key "${key}" --value "${value}"
assert_success $?

answer="$( get_rest_api_db --map "${db_id}" --key "${key}" )"
assert_success $?
detail "Answer = ${answer}"
assert_not_empty "${answer}"
assert_equals "${value}" "${answer}"

