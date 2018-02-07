#!/usr/bin/env bash

answer=$( get_network_adapters_by_type )
assert_failure $?

answer=$( get_network_adapters_by_type --selection 'lo' )
assert_success $?
assert_not_empty "${answer}"
detail "${answer}"

detail "$( get_network_adapter_types )"
