#!/usr/bin/env bash

map_out="$( hprint --map "nomap" )"
assert_success $?

__stdout "${map_out}"

assert_not_empty "${TRIAL_MAP}"

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"
