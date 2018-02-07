#!/usr/bin/env bash

answer=$( optlistex )
assert_success $?

answer=$( optlistex "abcd:e." )
assert_success $?
detail "getopts handling : ${answer}"
assert_equals "a b c d: e." "${answer}"
