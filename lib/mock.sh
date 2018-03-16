#!/usr/bin/env bash

###############################################################################
# Copyright (c) 2018.  All rights reserved. 
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

###############################################################################
#
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Mock Handling
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.1
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    mock
#
###############################################################################

# shellcheck disable=SC2016,SC1090,SC2039,SC2086,SC1117

__initialize_mock()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  __load __initialize_base_logging "${SLCF_SHELL_TOP}/lib/base_logging.sh"

  __initialize '__initialize_mock'
}

__prepared_mock()
{
  __prepared '__prepared_mock'
}

mock()
{
  typeset RC="${PASS}"
  typeset varname=
  typeset match_cond=
  typeset value=
  typeset printfile="${NO}"
  typeset channel="MOCK_$$"

  OPTIND=1
  while getoptex "v: var: c: cond: value: channel: return-file" "$@"
  do
    case "${OPTOPT}" in
    'v'|'var'          ) varname="${OPTARG}";;
    'c'|'cond'         ) match_cond="${OPTARG}";;
        'value'        ) value="${OPTARG}";;
        'channel'      ) channel="${OPTARG}";;
        'return-file'  ) printfile="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${varname}" ] && return "${FAIL}"

  if [ "$( is_channel_in_use --channel "${channel}" )" -eq "${NO}" ]
  then
    tmpmockfile="$( make_temp_file )"
    associate_file_to_channel --channel "${channel}" --file "${tmpmockfile}" --ignore-file-existence
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  else
    tmpmockfile=$( find_output_file --channel "${channel}" )
  fi

  typeset match_cond_result="${FAIL}"

  [ -z "${match_cond}" ] && match_cond_result="${PASS}"
  if [ "${match_cond_result}" -ne "${PASS}" ]
  then
    if eval "[ ${match_cond} ]"
    then
      match_cond_result="${PASS}"
    fi
  fi

  if [ "${match_cond_result}" -eq "${PASS}" ]
  then
    append_output --data "${varname}=${value}" --channel "${channel}"
  fi

  [ "${printfile}" -eq "${YES}" ] && printf "%s\n" "${tmpmockfile}"
  return "${RC}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'

if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_logging.sh"
fi

__initialize_mock
__prepared_mock