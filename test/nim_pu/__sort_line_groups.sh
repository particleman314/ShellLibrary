#!/bin/sh

sample=''
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_empty "${answer}"

sample='1:6'
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals '1:6' "${answer}"

sample='1:6 8:12'
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals '1:6 8:12' "${answer}"

sample='1:6 5:12'
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals '1:12' "${answer}"

sample='1:6 6:12'
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals '1:12' "${answer}"

sample='1:6 5:12 3:5'
answer=$( __sort_line_groups "${sample}" )
RC=$?
assert_success "${RC}"
assert_equals '1:12' "${answer}"
