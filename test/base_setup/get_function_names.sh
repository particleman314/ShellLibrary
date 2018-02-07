#!/usr/bin/env bash

answer=$( get_function_names )
detail "Function Names Found :"
detail --multi "${answer}"

assert_match spinner "${answer}"
assert_not_match blah "${answer}"
assert_not_match '_inner' "${answer}"
assert_match assert_match "${answer}"
