#!/bin/sh

assert_empty "${JUNK_FILES}"

sample_test_file="${SLCF_TEST_SUBSYSTEM_TEMPDIR}/xyz"
touch "${sample_test_file}"

__add_junk_file "${sample_test_file}"
__cleanup_junk_files

expectation=$( [ ! -f "${sample_test_file}" ] && printf "%d\n" "${PASS}" || printf "%d\n" "${FAIL}" )
assert_equals "${expectation}" "${PASS}"
