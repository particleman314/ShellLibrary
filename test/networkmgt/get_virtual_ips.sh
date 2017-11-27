#!/bin/sh

answer=$( get_virtual_ips )
assert_success $?
assert_empty "${answer}"
