#!/bin/sh

assert_empty "${__SSH_COMMANDS}"

__add_ssh_command --cmd 'ssh root@10.1.1.1 "ls -1"'
assert_not_empty "${__SSH_COMMANDS}"

__clear_ssh_commands
assert_empty "${__SSH_COMMANDS}"

__add_ssh_command --cmd 'ssh root@10.11.1.1 "mkdir -p hhhh"'
__add_ssh_command --cmd 'ssh root@10.11.1.1 "help"'

assert_not_empty "${__SSH_COMMANDS}"
detail "${__SSH_COMMANDS}"

__clear_ssh_commands
