#!/usr/bin/env bash

answer=$( __get_support_ipv_key )
RC=$?
assert_success "${RC}"
assert_equals 'inet' "${answer}"

answer=$( __get_support_ipv_key 4 )
RC=$?
assert_success "${RC}"
assert_equals 'inet' "${answer}"

answer=$( __get_support_ipv_key 6 )
RC=$?
assert_success "${RC}"
assert_equals 'inet6' "${answer}"
