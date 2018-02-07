#!/usr/bin/env bash

answer=$( __get_sequence )
RC=$?
assert_empty "${answer}"
assert_failure "${RC}"

answer1=$( __get_sequence -9 9 )
RC=$?
assert_not_empty "${answer1}"
accounting=$( __get_word_count --non-file "${answer1}" )
#assert_equals 19 "${accounting}"
assert_success "${RC}"

answer2=$( __get_sequence 5 1 -3 )
RC=$?
assert_not_empty "${answer2}"
assert_equals 2 $( __get_word_count --non-file "${answer2}" )
assert_success "${RC}"

answer3=$( __get_sequence 5 1 0 )
RC=$?
assert_empty "${answer3}"
assert_success "${RC}"

answer4=$( __get_sequence 2 2 6 )
RC=$?
assert_not_empty "${answer4}"
assert_equals 1 $( __get_word_count --non-file "${answer4}" )
assert_equals 2 "${answer4}"
assert_success "${RC}"
