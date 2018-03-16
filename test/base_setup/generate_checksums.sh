#!/usr/bin/env bash

samplefile='test_base_setup.sh'
assert_not_empty "${samplefile}"
assert_is_file "${samplefile}"

answer="$( generate_checksums )"
assert_failure $?
assert_equals ':' "${answer}"

answer="$( generate_checksums --filename "${samplefile}" )"
RC=$?

\which 'md5sum' >/dev/null 2>&1
has_md5=$?

\which 'sha1sum' >/dev/null 2>&1
has_sha1=$?

if [ "${has_md5}" -ne "${FAIL}" ] || [ "${has_sha1}" -ne "${FAIL}" ]
then
  assert_success "${RC}"
  assert_not_equals ':' "${answer}"

  detail "Checksum --> ${answer}"
  checksums='5d879b5c37f39391dc0afa5ad6581713:9d4982b4270c5b103980e1f6c710614466799711'
  assert_equals "${checksums}" "${answer}"
fi