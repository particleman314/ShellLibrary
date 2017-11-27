#!/bin/sh

sleep_func -s 1 --old-version
assert_success $?

sleep_func -s 5000
assert_success $?
