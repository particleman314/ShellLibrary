#!/bin/sh

std_opts="--suppress ${YES} --dnr"

assert_success ${std_opts} "${YES}"
assert_failure "$( __get_last_result )"

assert_success ${std_opts} "${NO}"
assert_success "$( __get_last_result )"

assert_success ${std_opts} "${PASS}"
assert_success "$( __get_last_result )"

assert_success ${std_opts} "${FAIL}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
