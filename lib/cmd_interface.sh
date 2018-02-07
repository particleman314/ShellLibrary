#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2017.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Command Interface Wrapper
## @Application      : Product Functionality
## @Language         : Bourne Shell
## @Version          : 1.01
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    call
#
###############################################################################

# shellcheck disable=SC2039,SC2016,SC2068

[ -z "${ALLOWED_CMD_INTERFACE_OPTIONS}" ] && ALLOWED_CMD_INTERFACE_OPTIONS='c: cmd: d dryrun s: channel: f: output-file: o save-output'

__initialize_cmd_interface()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __initialize '__initialize_cmd_interface'
}

__prepared_cmd_interface()
{
  __prepared '__prepared_cmd_interface'
}

###
### Must use the unified interface for issue_cmd or issue_ssh_cmd
###
call()
{
  __debug $@

  typeset ip_option_parameters='--ip --remote-ip --host-ip'

  if [ $# -gt 0 ]
  then
    typeset iop=
    for iop in ${ip_option_parameters}
    do
      typeset has_ip_option=$( contains_option "${iop}" $@ )
      [ "${has_ip_option}" -eq "${YES}" ] && break
    done

    if [ "${has_ip_option}" -eq "${YES}" ]
    then
      issue_ssh_cmd "$@"
    else
      issue_cmd "$@"
    fi
    return $?
  else
    return "${FAIL}"
  fi
}

# ---------------------------------------------------------------------------
__initialize_cmd_interface
__prepared_cmd_interface
