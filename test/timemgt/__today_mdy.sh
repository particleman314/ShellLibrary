#!/bin/sh

answer=$( __today )
assert_success $?
assert_not_empty "${answer}"
