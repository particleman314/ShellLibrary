#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

actual=0
assert_equals  ${std_opts} 0 "${actual}"
assert_success "$( __get_last_result )"

actual=2
assert_equals  ${std_opts} 0 "${actual}"
assert_failure "$( __get_last_result )"

actual=' '
assert_equals  ${std_opts} 0 "${actual}" 
assert_failure "$( __get_last_result )"

__reset_assertion_counters
