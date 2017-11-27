#!/bin/sh

actual=0
expectation=2

std_opts="--suppress ${YES} --dnr"

assert ${std_opts} "${expectation}" "${actual}"
assert_failure "$( __get_last_result )"
detail "Testing failure : $( __get_last_result ) -- ${expectation} -- ${actual}"

assert ${std_opts} "${expectation}" "${expectation}" 
assert_success "$( __get_last_result )"
detail "Testing success : $( __get_last_result )"

__reset_assertion_counters