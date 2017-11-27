#!/bin/sh

answer=$( get_network_adapter_types )
assert_success $?
assert_not_empty "${answer}"

num_adapters=$( count_items --data "${answer}" )
assert_not_equals 0 "${num_adapters}"
detail "${answer}"
