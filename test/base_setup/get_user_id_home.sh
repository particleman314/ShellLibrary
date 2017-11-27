#!/bin/sh

answer=$( get_user_id_home )
assert_success $?
assert_not_empty "${answer}"
