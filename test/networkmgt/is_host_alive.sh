#!/bin/sh

localip=$( get_machine_ip )
detail "Local ip = ${localip}"

answer=$( is_host_alive )
assert_failure $?

answer=$( is_host_alive --ping-count 20 )
assert_failure $?

answer=$( is_host_alive --host "${localip}" )
assert_success $?
assert_equals "${YES}" "${answer}"

answer=$( is_host_alive --host "${localip}" --ping-count 0 )
assert_success $?
assert_equals "${YES}" "${answer}"

answer=$( is_host_alive --host "${localip}" --ping-count A )
assert_success $?
assert_equals "${YES}" "${answer}"
