#!/bin/sh

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/blah.txt"

hpersist
assert_failure $?

hpersist --map 'NOT_REAL_MAP_VARIABLE'
assert_failure $?

hpersist --filename "${tmpfile}"
assert_failure $?

hput --map "${TRIAL_MAP}" --key count --value 1
hput --map "${TRIAL_MAP}" --key hub --value '1.2.3.4'

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

hpersist --map "${TRIAL_MAP}" --filename "${tmpfile}"
assert_success $?

has_size="${NO}"
[ -s "${tmpfile}" ] && has_size="${YES}"
assert_true "${has_size}"

schedule_for_demolition "${tmpfile}"

