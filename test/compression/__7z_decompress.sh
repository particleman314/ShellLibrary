#!/bin/sh

compression_file='compressed_file.txt.7z'
assert_is_file "${compression_file}"

outputdir=$( make_temp_dir )
schedule_for_demolition "${outputdir}"

__7z_decompress
assert_failure $?

if [ -n "${uncompressor_7z}" ]
then
  answer_dir=$( __7z_decompress --input "${compression_file}" )
  assert_success $?
  detail "Answer Dir = ${answer_dir}"
  assert_is_file "${answer_dir}/compressed_file.txt"
  assert_equals 'Hello World' "$( cat "${answer_dir}/compressed_file.txt" )"
  schedule_for_demolition "${answer_dir}"
fi

__7z_decompress --output-dir "${outputdir}"
assert_failure $?

if [ -n "${uncompressor_7z}" ]
then
  __7z_decompress --input "${compression_file}" --output-dir "${outputdir}"
  assert_success $?
  assert_is_file "${outputdir}/compressed_file.txt"
  assert_equals 'Hello World' "$( cat "${outputdir}/compressed_file.txt" )"
fi
