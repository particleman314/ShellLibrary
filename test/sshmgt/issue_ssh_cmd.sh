#!/bin/sh

OLD_WAREHOUSE='10.238.40.43'

output=$( __issue_ssh_cmd "ssh root@${OLD_WAREHOUSE} \"ls -1\"" )
assert_success $?
assert_not_empty "${output}"

output=$( __issue_ssh_cmd "ssh root@${OLD_WAREHOUSE} \"mkdir -p hhhh; rm -rf hhhh\"" )
assert_success $?
assert_empty "${output}"

output=$( __issue_ssh_cmd "ssh root@${OLD_WAREHOUSE} \"cat xyz\"" )
assert_failure $?
assert_not_empty "${output}"

__clear_ssh_commands
