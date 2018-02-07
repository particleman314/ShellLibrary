#!/usr/bin/env bash

answer=$( get_user_id_home )
assert_success $?
assert_not_empty "${answer}"
