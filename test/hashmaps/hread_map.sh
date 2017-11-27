#!/bin/sh

tmpfile="${SUBSYSTEM_TEMPORARY_DIR}/trial_map.txt"

hread_map
assert_failure $?

hread_map --filename "${tmpfile}"
assert_failure $?

hput --map "${TRIAL_MAP}" --key count --value 1
hput --map "${TRIAL_MAP}" --key hub --value '1.2.3.4'
map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

hpersist --map "${TRIAL_MAP}" --filename "${tmpfile}"
assert_success $?

hclear --map "${TRIAL_MAP}"
assert_empty $( hkeys --map "${TRIAL_MAP}" )
map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

hread_map --filename "${tmpfile}"
mapname=$( hget_mapname --filename "${tmpfile}" )
assert_equals "${mapname}" 'trial_map'

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"
assert_not_empty $( hkeys --map "${TRIAL_MAP}" )

schedule_for_demolition "${tmpfile}"

