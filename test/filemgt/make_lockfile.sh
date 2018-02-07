#!/usr/bin/env bash

tempdir="${SUBSYSTEM_TEMPORARY_DIR}"

answer=$( make_lockfile -s -r --directory "${tempdir}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals "${tempdir}/.lockfile" "${answer}"
schedule_for_demolition "${tempdir}/.lockfile"

tmplockdir="${tempdir}/LOCKFILES"

make_lockfile --directory "${tmplockdir}"
assert_success $?
assert_is_file "${tmplockdir}/.lockfile"

answer=$( make_lockfile -r --directory "${tmplockdir}" --lock-file '.mylock' )
assert_success $?
assert_is_file "${tmplockdir}/.mylock"
assert_equals "${tmplockdir}/.mylock" "${answer}"

#answer=$( make_lockfile -r --directory "${tmplockdir}" --lock-file '.mylock2' --msg 'This is a sample message' --permissions 000 )
#assert_success $?
#[ $( get_user_id ) == 'root' ] && assert_is_file "${tmplockdir}/.mylock2"

#[ -n "${CANOPUS_DETAIL}" ] && [ "${CANOPUS_DETAIL}" -gt 0 ] && \cat "${tmplockdir}/.mylock2"

schedule_for_demolition "${tmplockdir}"
