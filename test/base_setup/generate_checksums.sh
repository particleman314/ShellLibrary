#!/usr/bin/env bash

samplefile='test_base_setup.sh'
assert_not_empty "${samplefile}"
assert_is_file "${samplefile}"

answer="$( generate_checksums )"
assert_failure $?
assert_equals ':' "${answer}"

answer="$( generate_checksums --filename "${samplefile}" )"
assert_success $?
assert_not_equals ':' "${answer}"

detail "Checksum --> ${answer}"
checksums='5d879b5c37f39391dc0afa5ad6581713:9d4982b4270c5b103980e1f6c710614466799711'
assert_equals "${checksums}" "${answer}"
