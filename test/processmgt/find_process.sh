#!/usr/bin/env bash

answer=$( find_process )
assert_failure $?
assert_false "${answer}"

answer=$( find_process --process-id bash )
assert_success $?
assert_true "${answer}"

answer=$( find_process --process-id blah )
assert_success $?
assert_false "${answer}"
