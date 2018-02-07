#!/usr/bin/env bash

OLD_WAREHOUSE='10.238.40.43'
assert_empty "${__SSH_COMMANDS}"

__add_ssh_command --cmd "ssh root@${OLD_WAREHOUSE} \"ls -1\""
assert_not_empty "${__SSH_COMMANDS}"

__clear_ssh_commands
assert_empty "${__SSH_COMMANDS}"

__add_ssh_command --cmd "ssh root@${OLD_WAREHOUSE} \"mkdir -p hhhh; rm -rf hhhh\""

assert_not_empty "${__SSH_COMMANDS}"
detail "${__SSH_COMMANDS}"

outfiles=$( __execute_ssh_cmds )
assert_equals 0 $?

schedule_for_demolition "$( get_element --data "${outfile}" --id 1 --separator ':' )"
schedule_for_demolition "$( get_element --data "${outfile}" --id 2 --separator ':' )"

__clear_ssh_commands
