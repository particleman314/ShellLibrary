#!/usr/bin/env bash

std_opts="--suppress ${YES} --dnr"

###
### Reset the internal pointer to a known starting point
###
bypass_recording='--disable-filename'

__record_pass ${bypass_recording} > /dev/null

answer="$( __get_last_result )"
assert_success "${answer}"

__record_fail ${bypass_recording} > /dev/null

answer="$( __get_last_result )"
assert_failure "${answer}"

__record_skip ${bypass_recording} > /dev/null

answer="$( __get_last_result )"
assert_equals "${__SKIP}" "${answer}"

__record_pass ${bypass_recording} > /dev/null

answer="$( __get_last_result )"
assert_success "${answer}"

__reset_assertion_counters
