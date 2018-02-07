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
## @Software Package : Shell Automated Testing -- Network Assertions
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.03
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __v4
#    assert_ipv4
#    assert_ipv6
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2086

[ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

# shellcheck source=/dev/null

[ -z "${PASS}" ] && . "${SLCF_SHELL_TOP}/lib/assertions.sh"

__v4()
{
  if [ -z "$1" ]
  then
    print_no
    return "${PASS}"
  fi

  typeset reduced="${1#"$1%%[!0]*"}"
  if [ "${reduced}" != "$1" ]
  then
    print_no
    return "${PASS}"
  fi

  if [ "$1" -lt 256 ] && [ "$1" -ge 0 ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

assert_ipv4()
{
  typeset expectation="$1"
  typeset components="$( printf "%s\n" "${expectation}" | \sed -e 's#\.# #g' )"

  typeset num_components="$( __get_word_count ${components} )"
  if [ "${num_components}" -ne 4 ]
  then
    assert_fail "${PASS}"
    return "${PASS}"
  fi

  typeset ntaddr=
  for ntaddr in ${components}
  do
    typeset iprange="$( __v4 "${ntaddr}" )"
    if [ ${iprange} -eq "${NO}" ]
    then
      assert_fail "${PASS}"
      return "${PASS}"
    fi
  done

  assert_success "${PASS}"
  return "${PASS}"
}

assert_ipv6()
{
  typeset expectation="$1"
  if [ "${expectation}" != "${1#[0-9A-Fa-f]*:}" ]
  then
    if [ "${expectation}" == "${expectation#*[^0-9A-Fa-f:]}" ]
    then
      if [ "${expectation#*[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]}" == "${expectation#*:*:*:*:*:*:*:*:*:}" ]
      then
        assert_true "${YES}"
      else
        assert_false "${NO}"
      fi
    else
      assert_false "${NO}"
    fi
  else
    assert_false "${NO}"
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
