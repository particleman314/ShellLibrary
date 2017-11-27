#!/bin/sh

compression_file='compressed_file.txt.gz'
assert_is_file "${compression_file}"

answer=$( decompression --compress-file "${compression_file}" )
assert_success $?
assert_not_empty "${answer}"
detail "Decompression directory : ${answer}"

schedule_for_demolition "${answer}"

compression_file='compressed_file.txt.tar.gz'
answer=$( decompression --compress-file "${compression_file}" )
assert_success $?
assert_not_empty "${answer}"
detail "Decompression directory : ${answer}"

schedule_for_demolition "${answer}"
