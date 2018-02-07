#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

mapfilename="${SUBSYSTEM_TEMPORARY_DIR}/haccess_test.map"
hpersist --map "${TRIAL_MAP}" --filename "${mapfilename}"

answer=$( haccess_keys_via_file --filename "${mapfilename}" )
assert_not_empty "${answer}"
detail "Keys --> ${answer}"
