#!/usr/bin/env bash

###############################################################################
# Copyright (c) 2017.  All rights reserved. 
# Mike Klusman IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, Mike Klusman IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# Mike Klusman EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
###############################################################################

###
### Only run the tests in interactive mode (outside the harness)
###
. "${SLCF_SHELL_TOP}/lib/${LIBRARY_FUNCTION_FILE}.sh"

SUBSYSTEM_TEMPORARY_DIR='/tmp'
export SUBSYSTEM_TEMPORARY_DIR;

for __tf in $@
do
  [ -f "${SLCF_SHELL_TOP}/lib/__setup_${LIBRARY_FUNCTION_FILE}.sh" ] && . "${SLCF_SHELL_TOP}/lib/__setup_${LIBRARY_FUNCTION_FILE}.sh"

  if [ -f "${__tf}" ]
  then
    printf "\n%s\n\n" "Running test --> ${__tf}"
    . "${__tf}"
  fi
done

[ $# -gt 0 ] && printf "\n"
