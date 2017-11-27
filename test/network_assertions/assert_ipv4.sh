#!/bin/sh

ipv4_addr='192.168.0.1'
non_ipv4_addr='188'

assert_ipv4 "${ipv4_addr}"
assert_ipv4 "${non_ipv4_addr}"
