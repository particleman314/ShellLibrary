#!/usr/bin/env bash

ipv6_addr='ffc0::1'
non_ipv6_addr='hhhh:jdfl::1'

force_skip
assert_ipv6 "${ipv6_addr}"

assert_ipv6 "${non_ipv6_addr}"
clear_force_skip
