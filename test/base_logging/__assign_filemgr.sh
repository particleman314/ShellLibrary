#!/bin/sh

__assign_filemgr
assert_failure $?

__assign_filemgr '/blah/xyz'
assert_failure $?
