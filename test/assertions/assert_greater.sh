#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

input1=0
input2=2

assert_greater  ${std_opts} "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

input1=2
input2=2

assert_greater  ${std_opts} "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

input1=6
input2=2

assert_greater  ${std_opts} "${input1}" "${input2}"
assert_success "$( __get_last_result )"

__reset_assertion_counters
