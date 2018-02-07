#!/usr/bin/env bash

assert_not_empty "${TEST_JSON}"

__disable_json_failure 2
assert_not_equals 0 "${__JSON_FAILURE_SUPPRESSION}"

__enable_json_failure
assert_equals 0 "${__JSON_FAILURE_SUPPRESSION}"
