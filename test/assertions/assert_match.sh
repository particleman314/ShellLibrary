#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

actual='abc'
expectation='def'

assert_match ${std_opts} "${expectation}" "${actual}"
assert_failure "$( __get_last_result )"

expectation='abc'
assert_match ${std_opts} "${expectation}" "${actual}"
assert_success "$( __get_last_result )"

expectation='abc '
assert_match ${std_opts} "${expectation}" "${actual}"
assert_failure "$( __get_last_result )"

actual='Here is the alphabet abcdefghijk...'
assert_match ${std_opts} "${expectation}" "${actual}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
