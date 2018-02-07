#!/usr/bin/env bash

# tag : library,sample #### This is a sample tag definition

answer=$( contains_option 'h' '-h -i -k jfkfhd' )
assert_success $?
assert_true "${answer}"

answer=$( contains_option 'length|width' '--length 10 --help' )
assert_success $?
assert_true "${answer}"
