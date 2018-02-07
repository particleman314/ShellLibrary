#!/usr/bin/env bash

answer=$( popd )
assert_equals "${PWD}" "${answer}"

answer=$( pushd "${SLCF_SHELL_FUNCTIONDIR}" )
assert_not_empty "${answer}"

detail --multi ${answer}

answer=$( dirs )
#assert_match "shell_functions" "${answer}"

detail "Dir stack list : "
detail --multi ${answer}
