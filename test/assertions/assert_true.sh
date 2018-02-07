#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

assert_true ${std_opts} "${YES}" 
assert_success "$( __get_last_result )"

assert_true ${std_opts} "${NO}"
assert_failure "$( __get_last_result )"

assert_true ${std_opts} "${PASS}"
assert_failure "$( __get_last_result )"

assert_true ${std_opts} "${FAIL}"
assert_success "$( __get_last_result )"

__reset_assertion_counters
