#!/bin/sh

sample_password='XYZ'

answer=$( build_passwd_entry "${sample_password}" )
assert_success $?
assert_not_empty "${answer}"
detail "Defined Encoded Password --> ${answer}"
