#!/usr/bin/env bash

answer="$( get_artifactory_user )"
assert_success $?
assert_empty "${answer}"

set_artifactory_user --value 'klumi01'
assert_success $?

answer="$( get_artifactory_user )"
assert_success $?
assert_equals "${answer}" 'klumi01'
