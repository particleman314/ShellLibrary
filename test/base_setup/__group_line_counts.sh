#!/bin/sh

answer=$( __group_line_counts )
RC=$?
assert_empty "${answer}"
assert_equals "${PASS}" "${RC}"

answer=$( __group_line_counts 1 2 3 5 6 7 )
RC=$?
assert_not_empty "${answer}"
assert_equals '1:3 5:7' "${answer}"

answer=$( __group_line_counts 1 5 9 34 35 38 39 40 )
RC=$?
assert_not_empty "${answer}"
assert_equals '1:1 5:5 9:9 34:35 38:40' "${answer}"
