#!/usr/bin/env bash

answer=$( get_hostfile )
assert_success $?
assert_not_empty "${answer}"
