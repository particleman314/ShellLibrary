#!/bin/sh

current_dir=$( pwd -L )

force_skip
change_dir
assert_failure $?

change_dir "${SLCF_SHELL_TOP}"
assert_success $?

change_dir "${current_dir}"
clear_force_skip
