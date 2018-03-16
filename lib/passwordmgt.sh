#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2016.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Password Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.10
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    build_passwd_entry
#    decode_passwd
#    encode_passwd
#    full_decode
#    get_password_prefix
#    get_password_suffix
#    set_password_prefix
#    set_password_suffix
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2181

if [ -z "${__DEFAULT_PASSWORD_PREFIX}" ]
then
  __DEFAULT_PASSWORD_PREFIX='ENC{{{'
  __DEFAULT_PASSWORD_SUFFIX='}}}'

  __PASSWORD_PREFIX="${__DEFAULT_PASSWORD_PREFIX}"
  __PASSWORD_SUFFIX="${__DEFAULT_PASSWORD_SUFFIX}"
fi

__initialize_passwordmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  __initialize "__initialize_passwordmgt"
}

__prepared_passwordmgt()
{
  __prepared "__prepared_passwordmgt"
}

build_passwd_entry()
{
  typeset pwd_entry="$1"
  [ -z "${pwd_entry}" ] && return "${FAIL}"
  printf "%s\n" "$( get_password_prefix )${pwd_entry}$( get_password_suffix )"
  return "${PASS}"
}

decode_passwd()
{
  typeset input="$1"

  typeset prefix="$( get_password_prefix )"
  typeset suffix="$( get_password_suffix )"

  typeset originput="${input}"

  input="$( printf "%s\n" "${input}" | \sed -e 's#\\{#{#g' -e 's#\\}#}#g' )"

  [ -n "${prefix}" ] && input="$( printf "%s\n" "${input}" | \sed -e "s#^${prefix}##" )"
  [ -n "${suffix}" ] && input="$( printf "%s\n" "${input}" | \sed -e "s#${suffix}\$##" )"
  [ "${originput}" != "${input}" ] && input="$( printf "%s\n" "${input}" | \base64 --decode )"

  printf "%s\n" "${input}"
  return "${PASS}"
}

encode_passwd()
{
  typeset input="$1"
  
  input="$( printf "%s" "${input}" | \base64 )"
  build_passwd_entry "${input}"

  return $?
}

full_decode()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${PASS}"

  while [ 1 == 1 ]
  do
    typeset reduced_input="$( decode_passwd "${input}" )"
    [ -z "${reduced_input}" ] || [ "${reduced_input}" == "${input}" ] && break
    input="${reduced_input}"
  done

  [ -n "${input}" ] && printf "%s\n" "${input}"
  return "${PASS}"
}

get_password_prefix()
{
  [ -n "${__PASSWORD_PREFIX}" ] && printf "%s" "${__PASSWORD_PREFIX}"
}

get_password_suffix()
{
  [ -n "${__PASSWORD_SUFFIX}" ] && printf "%s" "${__PASSWORD_SUFFIX}"
}

set_password_prefix()
{
  if [ $# -lt 1 ]
  then
    __PASSWORD_PREFIX=
    return "${PASS}"
  fi
  
  __PASSWORD_PREFIX="$1"
  return "${PASS}"
}

set_password_suffix()
{
 if [ $# -lt 1 ]
  then
    __PASSWORD_SUFFIX=
    return "${PASS}"
  fi
  
  __PASSWORD_SUFFIX="$1"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
fi

__initialize_passwordmgt
__prepared_passwordmgt
