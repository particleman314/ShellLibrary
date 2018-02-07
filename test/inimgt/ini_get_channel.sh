#!/usr/bin/env bash

answer="$( ini_get_channel )"
assert_success $?
assert_not_empty "${answer}"

detail "Std output channel : ${answer}"
