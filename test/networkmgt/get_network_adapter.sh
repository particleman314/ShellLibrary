#!/usr/bin/env bash

answer=$( get_network_adapter )
assert_success $?
assert_not_empty "${answer}"

detail "Determine network adapter : ${answer}"
