#!/usr/bin/env bash

answer=$( popd )
assert_equals "${PWD}" "${answer}"
detail "${answer}"

answer=$( pushd "${SLCF_SHELL_TOP}/lib" )
assert_not_empty "${answer}"
detail --multi "${answer}"

answer1=$( pushd "${SLCF_SHELL_TOP}" )
assert_not_empty "${answer1}"
force_skip
assert_equals "${answer1}" "${answer}"
clear_force_skip
detail --multi "${answer1}"

answer="$( dirs )"
force_skip
assert_match "shell_functions" "${answer}"
clear_force_skip

detail "Dir stack list :"
detail --multi "${answer}"
