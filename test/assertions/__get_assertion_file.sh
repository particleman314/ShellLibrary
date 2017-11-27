#!/bin/sh

std_opts="--suppress ${YES} --dnr"
need_reset="${NO}"

answer="$( __get_assertion_file )"
[ -z "${answer}" ] && needs_reset="${YES}"

assert_empty ${std_opts} "${answer}"

__setup_assertion_file 'xyz123'

answer="$( __get_assertion_file )"
assert_not_empty ${std_opts} "${answer}"

if [ "${need_reset}" -eq "${YES}" ]
then
  __reset_assertion_file
  __reset_assertion_counters
fi
