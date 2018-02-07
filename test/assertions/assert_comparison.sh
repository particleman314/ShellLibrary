#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

input1=0
input2=2

assert_comparison ${std_opts} --comparison '=' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'equal' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'eq' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lessthan' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'less' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lt' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '>' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterthan' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greater' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'gt' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<=' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lessequal' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'le' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '>=' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterequal' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'ge' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

input1=2
input2=2

assert_comparison ${std_opts} --comparison '=' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'equal' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'eq' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<' "${input1}" "${input2}"
assert_failure "$( __get_last_result )" 
assert_comparison ${std_opts} --comparison 'lessthan' "${input1}" "${input2}"
assert_failure "$( __get_last_result )" 
assert_comparison ${std_opts} --comparison 'less' "${input1}" "${input2}"
assert_failure "$( __get_last_result )" 
assert_comparison ${std_opts} --comparison 'lt' "${input1}" "${input2}"
assert_failure "$( __get_last_result )" 

assert_comparison ${std_opts} --comparison '>' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterthan' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greater' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'gt' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<=' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lessequal' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'le' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '>=' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterequal' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'ge' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

input1=6
input2=2

assert_comparison ${std_opts} --comparison '=' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'equal' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'eq' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lessthan' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'less' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lt' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '>' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterthan' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greater' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'gt' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '<=' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'lessequal' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'le' "${input1}" "${input2}"
assert_failure "$( __get_last_result )"

assert_comparison ${std_opts} --comparison '>=' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'greaterequal' "${input1}" "${input2}"
assert_success "$( __get_last_result )"
assert_comparison ${std_opts} --comparison 'ge' "${input1}" "${input2}"
assert_success "$( __get_last_result )"

__reset_assertion_counters
