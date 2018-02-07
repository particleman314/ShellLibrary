#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

apriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )

hadd_item --map "${TRIAL_MAP}" --key 'robot' --value '10.238.43.0'
assert_success $?

aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
number_items=$( count_items --data "$( printf "%s " ${aposteriori_robot_key_contents} )" )
assert 2 ${number_items}

assert_not_equals "${apriori_robot_key_contents}" "${aposteriori_robot_key_contents}"

hadd_item --map "${TRIAL_MAP}" --key robot --value "10.238.42.5"
aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
number_items=$( count_items --data "$( printf "%s " ${aposteriori_robot_key_contents} )" )
assert 3 ${number_items}

assert_not_equals "${apriori_robot_key_contents}" "${aposteriori_robot_key_contents}"

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

assert 2 $( hcount --map "${TRIAL_MAP}" )
