#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2016.  All rights reserved. 
# MIKE KLUSMAN IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, MIKE KLUSMAN IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# MIKE KLUSMAN EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
###############################################################################

###############################################################################
#
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Debugging
## @Application      : Support Functionality
## @Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __debug
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2068,SC2181

__debug()
{
  if [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ]
  then
    if [ $# -gt 0 ]
    then
      typeset args=
      typeset funcname=
      args="$( printf " %s" $@ )"
      if [ "${SHELL%%bash}" != "${SHELL}" ]
      then
        funcname="${FUNCNAME[1]#${DECORATION_STRING}}"
      else
        funcname='some function' # ${FUNCNAME[1]#${decoration_string}}
      fi
      printf "%s\n" "${TABBING} ${funcname} with arguments <'${args}' >" >> "$0_debug" 2>&1
    else
      printf "%s\n" "${TABBING} ${funcname}" >> "$0_debug" 2>&1 
    fi
  fi
  return "${PASS}"
}

__initialize_debugging()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )
  
  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  __initialize "__initialize_debugging"
}

__prepared_debugging()
{
  __prepared "__prepared_debugging"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'

if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
fi

__initialize_debugging
__prepared_debugging
