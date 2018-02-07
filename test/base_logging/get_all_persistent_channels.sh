#!/usr/bin/env bash

answer=$( get_all_persistent_channels )
detail "Persistent Channels : ${answer}"

answer2=$( get_number_persistent_files )
detail "Number Persistent Files : ${answer2}"

assert_equals "$( __get_line_count --non-file "${answer}" )" "${answer2}"

__cleanup_filemgr
