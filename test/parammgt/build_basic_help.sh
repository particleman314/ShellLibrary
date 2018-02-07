#!/usr/bin/env bash

answer=$( build_basic_help )
assert_success $?
assert_not_empty "${answer}"

detail "Build Basic Help : ${answer}"
