#!/bin/sh

std_opts="--suppress ${YES} --dnr"

actual=0
expectation=2
assert_not_equals ${std_opts} "${expectation}" "${actual}"
assert_success "$( __get_last_result )"

actual=2
expectation=2
assert_not_equals ${std_opts} "${expectation}" "${actual}"
assert_failure "$( __get_last_result )"

actual=6
expectation=2
assert_not_equals ${std_opts} "${expectation}" "${actual}"
assert_success "$( __get_last_result )"

__reset_assertion_counters
