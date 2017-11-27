#!/bin/sh

reserve_answer=$( __get_designer )
assert_success $?
assert_equals 'Michael.Klusman' "${reserve_answer}"

__set_designer 'Mike.Klusman'
assert_success $?

answer=$( __get_designer )
assert_success $?
assert_equals 'Mike.Klusman' "${answer}"

__set_designer
assert_failure $?

answer=$( __get_designer )
assert_success $?
assert_equals 'Mike.Klusman' "${answer}"

__set_designer "${reserve_answer}"
