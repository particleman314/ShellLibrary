#!/bin/sh

std_opts="--suppress ${YES} --dnr"

actual=
assert_empty ${std_opts} "${actual}"
assert_success "$( __get_last_result )"

actual=2
assert_empty ${std_opts} "${actual}"
assert_failure "$( __get_last_result )"

actual="' '"
assert_empty ${std_opts} "${actual}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
