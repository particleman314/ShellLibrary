#!/bin/sh

answer=$( show_loaded )
assert_failure $?

answer=$( show_loaded base_setup )
assert_success $?

[ -n "${answer}" ] && detail "---> ${answer}"

if [ -n "${SLCF_DEBUG}" ] && [ "${SLCF_DEBUG}" -ne 0 ]
then
  assert_not_empty "${answer}"
  assert_match 'base_setup' "${answer}"
fi
