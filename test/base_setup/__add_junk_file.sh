#!/bin/sh

assert_empty "${JUNK_FILES}"

__add_junk_file "$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/xyz123"
assert_empty "${JUNK_FILES}"

sample_test_file="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/xyz"
schedule_for_demolition "${sample_test_file}"
\touch "${sample_test_file}"

__add_junk_file "${sample_test_file}"
assert_not_empty "${JUNK_FILES}"
assert_equals 1 $( __get_word_count --non-file "${JUNK_FILES}" )

__cleanup_junk_files
