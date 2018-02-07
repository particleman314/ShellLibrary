#!/usr/bin/env bash

template='Four score and seven years ago...'

answer=$( join --data "${template}" --separator ':' )
assert_success $?
assert_equals 'Four:score:and:seven:years:ago...' "${answer}"

answer=$( join --data "${template}" --separator '/' )
assert_success $?
assert_equals 'Four/score/and/seven/years/ago...' "${answer}"

answer=$( join --separator 'k' )
assert_failure $?
assert_empty "${answer}"

