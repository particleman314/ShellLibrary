#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

mapfilename="${SUBSYSTEM_TEMPORARY_DIR}/haccess_test.map"
hpersist --map "${TRIAL_MAP}" --filename "${mapfilename}"

answer=$( haccess_entry_via_file --filename "${mapfilename}" --key 'robot' )
assert_not_empty "${answer}"
detail "Key [ robot ] --> ${answer}"

answer=$( haccess_entry_via_file --filename "${mapfilename}" --key 'hub' )
assert_not_empty "${answer}"
detail "Key [ hub ] --> ${answer}"
