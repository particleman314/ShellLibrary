#!/usr/bin/env bash

reserve_answer=$( __get_maintainer )
assert_success $?
assert_equals 'Michael.Klusman' "${reserve_answer}"

__set_maintainer 'Mike.Klusman'
assert_success $?

answer=$( __get_maintainer )
assert_success $?
assert_equals 'Mike.Klusman' "${answer}"

__set_maintainer
assert_failure $?

answer=$( __get_maintainer )
assert_success $?
assert_equals 'Mike.Klusman' "${answer}"

__set_maintainer "${reserve_answer}"
