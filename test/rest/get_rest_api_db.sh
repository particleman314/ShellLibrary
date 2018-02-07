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

answer="$( get_rest_api_db )"
assert_failure $?
assert_empty "${answer}"

answer="$( get_rest_api_db --map "${db_id}" )"
assert_failure $?
assert_empty "${answer}"

answer="$( get_rest_api_db --key 'my2Key' )"
assert_failure $?
assert_empty "${answer}"

answer="$( get_rest_api_db --map "${db_id}" --key 'noKey' )"
assert_success $?
assert_empty "${answer}"

answer="$( get_rest_api_db --map "${db_id}" --key "${key}" )"
assert_success $?
detail "Answer = ${answer}"
assert_not_empty "${answer}"
assert_equals "${value}" "${answer}"

