#!/usr/bin/env bash

answer=$( is_comment )
assert_success $?
assert_false "${answer}"

answer=$( is_comment --str 'Hello' )
assert_false "${answer}"

answer=$( is_comment --str '#hello' )
assert_true "${answer}"

answer=$( is_comment --str '|p' --comment-char '|' )
assert_true "${answer}"

reserve_cc=$( get_comment_char )
set_comment_char '###'
assert_success $?

detail "Previous comment characters : ${reserve_cc}"

answer=$( is_comment --str '##Hello' )
assert_false "${answer}"

answer=$( is_comment --str '###Mad World###' )
assert_true "${answer}"

set_comment_char "${reserve_cc}"
