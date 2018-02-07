#!/usr/bin/env bash

##############################################################################
# Type: Internal
# Description: Library Unit Test
# Function: calculate_run_time
#
# Tag: Library, Timing, library
# OS: Generic
#
# Author: Michael Klusman III   (CA)
# Date: 12/14/2016
#
# History:
#   01/11/2017 --> Updated to use SLCF prefixes
#
# Limitations: dependency on sleep function definition
##############################################################################

strfl="${SUBSYSTEM_TEMPORARY_DIR}/start_run.dat"
endfl="${SUBSYSTEM_TEMPORARY_DIR}/end_run.dat"

\date "+%s" > "${strfl}"
sleep_func -s 5 --old-version
\date "+%s" > "${endfl}"

answer=$( calculate_run_time --start "${strfl}" --end "${endfl}" )
assert_success $?
assert_not_empty "${answer}"
assert_equals "5.000" "${answer}"

schedule_for_demolition "${strfl}" "${endfl}"
