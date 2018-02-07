#!/usr/bin/env bash

assert_not_empty "${TEST_JSON}"

json_set_file
assert_failure $?

json_set_file --jsonfile "${TEST_JSON}"
assert_success $?
