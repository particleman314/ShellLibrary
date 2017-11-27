#!/bin/sh

answer=$( get_number_persistent_files )
detail "Number Persistent Files : ${answer}"

assert_greater_equal "${answer}" 0

__cleanup_filemgr
