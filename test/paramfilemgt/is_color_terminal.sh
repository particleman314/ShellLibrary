#!/usr/bin/env bash

###
### This test is depending on the OS flavor and how it is run
###
answer=$( is_color_terminal )
assert_success $?
assert_true "${answer}"
