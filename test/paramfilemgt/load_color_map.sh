#!/usr/bin/env bash

load_color_map --suppress
assert_success $?

assert_not_empty "${BLACK}"
assert_not_equals "${BLACK}" "${RESET}"
