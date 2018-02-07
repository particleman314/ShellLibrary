#!/usr/bin/env bash

compression_file='compression/compressed_file.txt.7z'

answer=$( __find_decompression_algorithm )
assert_failure $?
assert_empty "${answer}"

answer=$( __find_decompression_algorithm "${compression_file}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals '__7z_decompress' "${answer}"

compression_file='compression/compressed_file.txt.tar'

answer=$( __find_decompression_algorithm "${compression_file}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals '__tar_decompress' "${answer}"

compression_file='compressed_file.txt.tar.gz'

answer=$( __find_decompression_algorithm "${compression_file}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals '__gunzip_decompress __tar_decompress' "${answer}"

