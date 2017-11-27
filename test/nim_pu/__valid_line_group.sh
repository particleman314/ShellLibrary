#!/bin/sh

sample=''
answer=$( __valid_line_group "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals 0 "${answer}"

sample='1:2'
answer=$( __valid_line_group "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals 1 "${answer}"

sample='1|2'
answer=$( __valid_line_group "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals 0 "${answer}"

sample='1:2:6'
answer=$( __valid_line_group "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals 0 "${answer}"

