#!/bin/sh

#__today
answer=$( convert_time --num-seconds 0 )
assert_not_empty "${answer}"

assert $( __extract_seconds "${answer}" ) 0
assert $( __extract_minutes "${answer}" ) 0
assert $( __extract_hours "${answer}" ) 0

answer=$( convert_time --num-seconds 500 )
assert_not_empty "${answer}"

assert $( __extract_seconds "${answer}" ) 20
assert $( __extract_minutes "${answer}" ) 8
assert $( __extract_hours "${answer}" ) 0
