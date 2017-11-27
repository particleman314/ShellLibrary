#!/bin/sh

assert_not_empty "${TRIAL_MAP}"

mapfilename="${SUBSYSTEM_TEMPORARY_DIR}/haccess_test.map"
hpersist --map "${TRIAL_MAP}" --filename "${mapfilename}"

prior_data="$( haccess_entry_via_file --filename "${mapfilename}" --key 'robot' )"

detail "Original Data : Key [ robot ] --> ${prior_data}"

hchange_entry_via_file --filename "${mapfilename}" --key 'robot' --value '1.2.3.4'
answer="$( haccess_entry_via_file --filename "${mapfilename}" --key 'robot' )"
assert_not_empty "${answer}"
assert_equals "${prior_data} 1.2.3.4" "${answer}"

detail "New Data : Key [ robot ] --> ${answer}"

hchange_entry_via_file --filename "${mapfilename}" --key 'robot' --value '10.20.30.40' --replace
answer="$( haccess_entry_via_file --filename "${mapfilename}" --key 'robot' )"
assert_not_empty "${answer}"
assert_equals '10.20.30.40' "${answer}"

detail "Final Data : Key [ robot ] --> ${answer}"
