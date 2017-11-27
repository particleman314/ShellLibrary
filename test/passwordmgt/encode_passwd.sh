#!/bin/sh

sample_password='Mike_Klusman'

answer=$( encode_passwd "${sample_password}" )
assert_success $?
assert_not_empty "${answer}"
detail "Encoded Password --> ${answer}"
