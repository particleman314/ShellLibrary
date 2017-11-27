#!/bin/sh

load_parameter_file
assert_failure $?

rsrcdir="${SLCF_SHELL_RESOURCEDIR}"
assert_is_directory "${rsrcdir}"

paramfile="${rsrcdir}/common/colors.rc"

load_parameter_file --file "${paramfile}" --key 'BG_CYAN' --key 'FG_WHITE' --suppress
assert_success $?

assert_not_empty "${BG_CYAN}"
assert_equals "${BG_CYAN}" 46
assert_not_empty "${FG_WHITE}"
assert_equals "${FG_WHITE}" 37

detail "Parameter File : ${paramfile}"
load_parameter_file --file "${paramfile}" --suppress
assert_success $?
force_skip
assert_not_empty "${BG_RED}"
clear_force_skip

load_parameter_file --file "${rsrcdir}/common/no_real_file.rc" --suppress
assert_failure $?
