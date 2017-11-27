#!/bin/sh

reserve_answer=$( __get_company )
assert_success $?
assert_equals 'ca.com' "${reserve_answer}"

__set_company '.mil.gov'
assert_success $?

answer=$( __get_company )
assert_success $?
assert_equals '.mil.gov' "${answer}"

__set_company
assert_failure $?

answer=$( __get_company )
assert_success $?
assert_equals '.mil.gov' "${answer}"

__set_company "${reserve_answer}"
