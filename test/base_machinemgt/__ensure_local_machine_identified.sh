#!/usr/bin/env bash

assert_not_empty "${OSVARIETY}"

__ensure_local_machine_identified
assert_success $?
