#!/bin/sh

answer=$( __today_as_seconds )
assert_success $?
assert_not_empty "${answer}"
