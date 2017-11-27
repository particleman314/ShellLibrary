#!/bin/sh

has_sshkey
RC=$?
assert_true "${RC}"
