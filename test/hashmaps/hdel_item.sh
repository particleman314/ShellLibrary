#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

apriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )

hadd_item --map "${TRIAL_MAP}" --key 'robot' --value '10.238.43.0'
hadd_item --map "${TRIAL_MAP}" --key robot --value "10.238.42.5"

aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
num=$( count_items --data "$( printf "%s " "${aposteriori_robot_key_contents}" )" )
assert_equals 3 "${num}"

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"

hdel_item --map "${TRIAL_MAP}" --key robot --value '10.238.43.0'
aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
num=$( count_items --data "$( printf "%s " "${aposteriori_robot_key_contents}" )" )
assert_equals 2 "${num}"

assert 2 $( hcount --map "${TRIAL_MAP}" )

hdel_item --map "${TRIAL_MAP}" --key 'blah' --value 'xyz'

assert 2 $( hcount --map "${TRIAL_MAP}" )

hdel_item --map "${TRIAL_MAP}" --key hub --value 'xyz'

hub_values=$( hget --map "${TRIAL_MAP}" --key 'hub' )
assert_not_empty "${hub_values}"
number_items=$( count_items --data "$( printf "%s " ${hub_values} )" )
assert_equals 1 ${number_items}

hdel_item --map "${TRIAL_MAP}" --key 'hub' --value '10.238.41.252'
hub_values=$( hget --map "${TRIAL_MAP}" --key 'hub' )

assert_empty "${hub_values}"
assert 1 $( hcount --map "${TRIAL_MAP}" )

map_out="$( hprint --map "${TRIAL_MAP}" )"
assert_success $?

__stdout "${map_out}"
