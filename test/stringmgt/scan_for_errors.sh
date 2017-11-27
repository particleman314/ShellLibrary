#!/bin/sh

sample='/some/path/to/file.txt'

get_extension
RC=$?
assert_success "${RC}"

answer=$( get_extension "${sample}" )
assert_not_empty "${answer}"
assert_equals 'txt' "${answer}"

sample='blah.tar.gz'

answer=$( get_extension "${sample}" )
assert_not_empty "${answer}"
assert_equals 'gz' "${answer}"
