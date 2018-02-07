#!/usr/bin/env bash

download_from_teamcity
assert_failure $?

__set_teamcity_rest_address 'http://teamcity.dev.fco:8111'

user_id='klumi01'
user_pwd=$( build_passwd_entry 'SGF3YWlpMjAxOAo=' )

storage_directory=$( make_temp_dir )
schedule_for_demolition "${storage_directory}"

type='hub'
branch='develop/bus_2015q4'

download_from_teamcity --storage-dir "${storage_directory}" --user-id "${user_id}" --passwd "${user_pwd}" --tag '.lastFinished' --branch "${branch}" --type "${type}" --tc-rest-path 'httpAuth/repository/downloadAll/CMake_Bci_Hub_Package'
assert_success $?
assert_is_file "${storage_directory}/${branch}/${type}/output.zip"

type='robot'

download_from_teamcity --storage-dir "${storage_directory}" --user-id "${user_id}" --passwd "${user_pwd}" --tag '.lastFinished' --branch "${branch}" --type "${type}" --tc-rest-path 'httpAuth/repository/downloadAll/CMake_Bci_Robot_Package'
assert_success $?
assert_is_file "${storage_directory}/${branch}/${type}/output.zip"

outputfile='robot_complete.zip'

download_from_teamcity --storage-dir "${storage_directory}" --user-id "${user_id}" --passwd "${user_pwd}" --tag '.lastFinished' --branch "${branch}" --type "${type}" --outputfile "${outputfile}" --tc-rest-path 'httpAuth/repository/downloadAll/CMake_Bci_Robot_Package'
assert_success $?
assert_is_file "${storage_directory}/${branch}/${type}/${outputfile}"

xmlfile='teamcity/tc_trial_download.xml'
branch='develop/bus_ape'

assert_is_file "${xmlfile}"
download_from_teamcity --branch "${branch}" --type "${type}" --xmlfile "${xmlfile}" --xml-rootpath '/teamcity'
assert_success $?

branch='develop/feature/US56935_sql_response_fb1'

assert_is_file "${xmlfile}"
download_from_teamcity --branch "${branch}" --type "${type}" --xmlfile "${xmlfile}" --xml-rootpath '/teamcity'
assert_success $?
