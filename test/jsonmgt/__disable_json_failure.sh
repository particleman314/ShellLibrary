#!/usr/bin/env bash

assert_not_empty "${TEST_JSON}"

__disable_json_failure 2
assert_equals 1 "${__JSON_FAILURE_SUPPRESSION}"

__disable_json_failure 1
assert_equals 1 "${__JSON_FAILURE_SUPPRESSION}"
