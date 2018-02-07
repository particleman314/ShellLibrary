#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

assert_false ${std_opts} "${YES}"
assert_failure "$( __get_last_result )"

assert_false ${std_opts} "${NO}"
assert_success "$( __get_last_result )"

assert_false ${std_opts} "${PASS}"
assert_success "$( __get_last_result )"

assert_false ${std_opts} "${FAIL}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters

