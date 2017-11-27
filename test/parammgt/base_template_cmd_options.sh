#!/bin/sh

answer=$( base_template_cmd_options )
assert_success $?
assert_not_empty "${answer}"

detail "Basic template options : ${answer}"
