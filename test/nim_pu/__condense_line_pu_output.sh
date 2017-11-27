#!/bin/sh

answer=$( __condense_line_pu_output )
RC=$?
assert_empty "${answer}"
assert_not_equals "${PASS}" "${RC}"

answer=$( __condense_line_pu_output 'abc     PDS_I   6 abcdef' )
RC=$?
assert_equals 'abc PDS_I 6 abcdef' "${answer}"
assert_equals "${PASS}" "${RC}"

answer=$( __condense_line_pu_output 'abc PDS_PCH 1 a' )
RC=$?
assert_equals 'abc PDS_PCH 1 a' "${answer}"
assert_equals "${PASS}" "${RC}"

answer=$( __condense_line_pu_output "abc${__NIM_PU_ELEMENT_CONTINTUATION}PDS_PCH${__NIM_PU_ELEMENT_CONTINTUATION}1${__NIM_PU_ELEMENT_CONTINTUATION}a" )
RC=$?
assert_equals 'abc PDS_PCH 1 a' "${answer}"
assert_equals "${PASS}" "${RC}"
