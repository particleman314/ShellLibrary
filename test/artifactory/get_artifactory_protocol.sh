#!/bin/sh

answer="$( get_artifactory_protocol )"
assert_success $?
detail "Protocol = ${answer}"
assert_equals 'http' "${answer}"

set_artifactory_protocol --value 'sftp'
assert_success $?

answer="$( get_artifactory_protocol )"
assert_success $?
assert_equals 'sftp' "${answer}"
