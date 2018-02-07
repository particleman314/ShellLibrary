#!/usr/bin/env bash

need_reset="${NO}"

answer="$( __get_assertion_file )"
[ -z "${answer}" ] && needs_reset="${YES}"

assert_empty --suppress "${YES}" --dnr "${answer}"

__setup_assertion_file 'xyz987'

answer="$( __get_assertion_file )"
assert_not_empty --suppress "${YES}" --dnr "${answer}"

if [ "${needs_reset}" -eq "${YES}" ]
then
  __reset_assertion_file
  __reset_assertion_counters
fi
