#!/bin/sh

answer=$( get_user_id )
assert_not_empty "${answer}"

detail "---> User located as ${answer}"
