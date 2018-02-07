#!/usr/bin/env bash

has_sshkey
RC=$?
assert_true "${RC}"
