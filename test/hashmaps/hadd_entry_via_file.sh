#!/bin/sh

assert_not_empty "${TRIAL_MAP}"

mapfilename="${SUBSYSTEM_TEMPORARY_DIR}/haccess_test.map"
hpersist --map "${TRIAL_MAP}" --filename "${mapfilename}"

cat "${mapfilename}"

hadd_entry_via_file --filename "${mapfilename}" --key 'tunnel' --value 1
answer1=$( haccess_entry_via_file --filename "${mapfilename}" --key 'tunnel' )
echo "Tunnel = ${answer1}"
assert_not_empty "${answer1}"
assert_equals 1 "${answer1}"

cat "${mapfilename}"
new_hashmapfile="$( make_output_file --channel 'TEST_HASHMAP' )"
schedule_for_demolition "${new_hashmapfile}"

hadd_entry_via_file --filename "${new_hashmapfile}" --key 'new_entry' --value 9
answer2=$( haccess_entry_via_file --filename "${new_hashmapfile}" --key 'new_entry' )
assert_not_empty "${answer2}"
assert_equals 9 "${answer2}"

cat "${new_hashmapfile}"
