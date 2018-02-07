#!/usr/bin/env bash

assert_not_empty "${TEST_JSON}"

__disable_json_failure 2

json_exists
assert_false $?

json_exists --jsonfile "${TEST_JSON}"
assert_false $?

force_skip
json_exists --jsonfile "${TEST_JSON}" --jpath '{message: .commit.message}'
assert_true $?

json_exists --jsonfile "${TEST_JSON}" --jpath '{blah: .commit.blah}'
assert_false $?
clear_force_skip

__enable_json_failure
