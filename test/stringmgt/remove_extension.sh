#!/bin/sh

sample='/some/path/to/file.txt'

remove_extension
RC=$?
assert_success "${RC}"

answer=$( remove_extension "${sample}" )
assert_not_empty "${answer}"
assert_equals '/some/path/to/file' "${answer}"
