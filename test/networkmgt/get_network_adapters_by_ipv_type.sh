#!/usr/bin/env bash

answer=$( get_network_adapters_by_ipv_type )
assert_success $?
assert_not_empty "${answer}"
assert_match 'lo' "${answer}"
detail "IPv4 network interfaces : ${answer}"

answer=$( get_network_adapters_by_ipv_type --ipv 6 )
assert_success $?
assert_not_empty "${answer}"
assert_match 'lo' "${answer}"
detail "IPv6 network interfaces : ${answer}"
