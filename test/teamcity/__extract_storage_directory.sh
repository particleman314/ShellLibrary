#!/bin/sh

answer=$( __extract_storage_directory )
assert_failure $?
assert_empty "${answer}"

answer=$( __extract_storage_directory --xmlfile 'teamcity/tc_trial_download.xml' )
assert_failure $?
assert_empty "${answer}"

answer=$( __extract_storage_directory --xml-rootpath '/teamcity' )
assert_failure $?
assert_empty "${answer}"

answer=$( __extract_storage_directory --xmlfile 'teamcity/tc_trial_download.xml' --xml-rootpath '/teamcity' )
assert_success $?
assert_not_empty "${answer}"
assert_equals "/mnt/fileshare/Users/mklusman/SECURED_HUB_ROBOT_DAILY_BITS" "${answer}"
detail "${answer}"
