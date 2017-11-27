#!/bin/sh

origfile='compressed_file.txt'
compression_file="${origfile}.gz"
assert_is_file "${compression_file}"

outputdir=$( make_temp_dir )
detail "OUTPUT_DIR = ${outputdir}"
schedule_for_demolition "${outputdir}"

__gunzip_decompress
assert_failure $?

answer_dir="$( __gunzip_decompress --input "${compression_file}" --keep-orig )"
assert_success $?
assert_is_file "${answer_dir}/${origfile}"
assert_equals 'Hello World' "$( \cat "${answer_dir}/${origfile}" )"
schedule_for_demolition "${answer_dir}/${origfile}"

__gunzip_decompress --output-dir "${outputdir}"
assert_failure $?

answer_dir="$( __gunzip_decompress --input "${compression_file}" --output-dir "${outputdir}" --keep-orig )"
assert_success $?

detail "$( \ls -al ${outputdir} )"
assert_is_file "${outputdir}/${origfile}"
assert_equals 'Hello World' "$( \cat "${outputdir}/${origfile}" )"
