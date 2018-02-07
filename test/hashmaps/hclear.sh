#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

map_out="$( hprint --map "${TRIAL_MAP}" )"
__stdout "Map contents after 'hclear' call #0..."
__stdout
__stdout "${map_out}"
__stdout

apriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
assert_not_empty "${apriori_robot_key_contents}"

#hclear --map "${TRIAL_MAP}"
#assert_success $?

#map_out="$( hprint --map "${TRIAL_MAP}" )"
#__stdout "Map contents after 'hclear' call #1..."
#__stdout
#__stdout "${map_out}"
#__stdout

aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
__stdout "Robot key contains (#1): ${aposteriori_robot_key_contents}"
__stdout

assert_not_empty "${aposteriori_robot_key_contents}"
assert_equals "${apriori_robot_key_contents}" "${aposteriori_robot_key_contents}"
#assert_empty "${aposteriori_robot_key_contents}"
#assert_not_equals "${apriori_robot_key_contents}" "${aposteriori_robot_key_contents}"

hadd_item --map "${TRIAL_MAP}" --key robot --value '10.238.42.5'
hadd_item --map "${TRIAL_MAP}" --key robot --value '10.238.43.0'

map_out="$( hprint --map "${TRIAL_MAP}" )"
__stdout "Map contents after 'hclear' call #2..."
__stdout
__stdout "${map_out}"
__stdout

aposteriori_robot_key_contents=$( hget --map "${TRIAL_MAP}" --key 'robot' )
__stdout "Robot key contains (#2): ${aposteriori_robot_key_contents}"
__stdout
num=$( count_items --data "$( printf "%s " "${aposteriori_robot_key_contents}" )" )
assert_equals 3 "${num}"
#assert_equals 2 "${num}"

#
# Counts the number of keys in the map
#
assert 2 $( hcount --map "${TRIAL_MAP}" )
#assert 1 $( hcount --map "${TRIAL_MAP}" )

map_out="$( hprint --map "${TRIAL_MAP}" )"
__stdout "Map contents after 'hclear' call #3..."
__stdout
__stdout "${map_out}"

