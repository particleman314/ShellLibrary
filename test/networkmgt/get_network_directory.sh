#!/bin/sh

answer=$( get_network_directory )
assert_success $?
assert_not_empty "${answer}"

detail "Network Directory : ${answer}"
