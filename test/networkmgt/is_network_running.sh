#!/bin/sh

network_adapter=$( get_network_adapter )
assert_not_empty "${network_adapter}"

network_adapter=$( get_element --data "${network_adapter}" --id 1 --separator=' ' )

detail "Network Adapter : ${network_adapter}"

answer=$( is_network_running )
assert_failure $?
assert_false "${answer}"

answer=$( is_network_running --adapter "${network_adapter}" )
assert_success $?
assert_true "${answer}"
