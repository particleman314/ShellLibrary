#!/usr/bin/env bash

localip=$( get_machine_ip )
assert_success $?

answer=$( is_ip_addr )
assert_failure $?
assert_false "${answer}"

answer=$( is_ip_addr --address '1.2.3' )
assert_success $?
assert_false "${answer}"

answer=$( is_ip_addr --address '5.6.7.8.9' )
assert_success $?
assert_false "${answer}"

answer=$( is_ip_addr --address '1.2.3.4' )
assert_success $?
assert_true "${answer}"
