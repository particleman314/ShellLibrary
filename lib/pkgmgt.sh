#!/bin/sh
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
## @Software Package : Shell Automated Testing -- Package Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.6
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __determine_package_manager
#    __get_package_manager
#    __install_package
#    __set_package_manager
#
###############################################################################

# shellcheck disable=SC2016

if [ -z "${__MACHINE_TYPE}" ]
then
  __MACHINE_TYPE=$( \uname -s )
  __SETUP_PKG="${NO}"
  __MACHINE_CLASSIFICATION=
fi

__initialize_pkgmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
}

__prepared_pkgmgt()
{
  __prepared '__prepared_pkgmgt'
}

__determine_packaging_system()
{
  typeset RC="${PASS}"
  typeset machine_rsrcdir="${SLCF_SHELL_TOP}/resources"

  case "${__MACHINE_TYPE}" in
  'SunOS'            ) __MACHINE_CLASSIFICATION='solaris'; machine_rsrcdir="${machine_rsrcdir}/Unix";;
  'AIX'              ) __MACHINE_CLASSIFICATION='aix'; machine_rsrcdir="${machine_rsrcdir}/Unix";;
  'HP-UX'|'HPUX'     ) __MACHINE_CLASSIFICATION='hpux'; machine_rsrcdir="${machine_rsrcdir}/Unix";;
  'Cygwin'|'Windows' ) __MACHINE_CLASSIFICATION='windows'; machine_rsrcdir="${machine_rsrcdir}/Windows";;
  'Linux'            ) __MACHINE_CLASSIFICATION="$( which_linux_variety_to_use )"; machine_rsrcdir="${machine_rsrcdir}/Linux";;
  *                  ) return "${FAIL}";;
  esac

  if [ -f "${machine_rsrcdir}/${__MACHINE_CLASSIFICATION}.pgs" ]
  then
    __use_resource "${machine_rsrcdir}/${__MACHINE_CLASSIFICATION}.pgs"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  fi

  if [ ! -f "${machine_rsrcdir}/.built_for_${__MACHINE_TYPE}" ]
  then
    # shellcheck source=/dev/null

    . "${machine_rsrcdir}/build_resources.sh ${__MACHINE_TYPE}"
    RC=$?
  fi

  return "${RC}"
}

__use_resource()
{
  typeset RC="${PASS}"

  [ -z "$1" ] || [ ! -f "$1" ] && return "${FAIL}";
  # shellcheck source=/dev/null
  . "$1"
  RC=$?

  [ "${RC}" -eq "${PASS}" ] && __SETUP_PKG="${YES}"
  return "${RC}"
}

which_linux_variety_to_use()
{
  typeset linux_distro='UNKNOWN'
  typeset RC=
  typeset distribution_files='/etc/redhat-release /etc/issue'

  for df in ${distribution_files}
  do
    [ ! -f "${df}" ] && continue
    \grep -iq 'RED HAT' "${df}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && linux_distro=redhat

    \grep -iq 'SUSE' "${df}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && linux_distro=suse

    \grep -iq 'UBUNTU' "${df}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && linux_distro=ubuntu

    \grep -iq 'DEBIAN' "${df}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && linux_distro=debian

    \grep -iq 'CENTOS' "${df}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && linux_distro=centos
  done
  printf "%s\n" "${linux_distro}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------

type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/constants.sh"
fi

__initialize_pkgmgt
__prepared_pkgmgt
