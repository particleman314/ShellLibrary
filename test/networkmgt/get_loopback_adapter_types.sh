#!/bin/sh

answer=$( get_loopback_adapter_types )
assert_success $?
assert_not_empty "${answer}"
assert_match 'lo' "${answer}"
detail "IPv4 loopback : ${answer}"

answer=$( get_loopback_adapter_types --ipv 6 )
assert_success $?
assert_not_empty "${answer}"
assert_match 'lo' "${answer}"
detail "IPv6 loopback : ${answer}"
