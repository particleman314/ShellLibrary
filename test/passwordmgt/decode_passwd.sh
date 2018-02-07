#!/usr/bin/env bash

sample_password='Mike Klusman'

answer=$( encode_passwd "${sample_password}" )
assert_success $?
detail "Encoded Password --> ${answer}"

answer=$( decode_passwd "${answer}" )
assert_success $?
assert_not_empty "${answer}"
detail "Decoded Password --> ${answer}"
