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
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- UIM Functionality
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    check_ade_deployment
#    determine_if_running_probe
#    get_nimaddress
#    get_nimaddress_ip
#    is_nimaddress
#
###############################################################################

__initialize_nim_functions()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_nim "${SLCF_SHELL_TOP}/lib/nim.sh"
  __load __initialize_nim_configuration "${SLCF_SHELL_FUNCTIONDIR}/nim_configuration.sh"
 
  __initialize "__initialize_nim_functions"
}

__prepared_nim_functions()
{
  __prepared "__prepared_nim_functions"
}

check_ade_deployment()
{
  typeset ade_jobid="$1"

  [ -z "${ade_jobid}" ] && return "${FAIL}"
  [ -z "${TEST_UIM_SERVER}" ] && return "${FAIL}"

  typeset UIMnimaddress=$( get_nimaddress "${TEST_UIM_SERVER}" )
  [ -z "${UIMnimaddress}" ] && return "${FAIL}"

  typeset has_processed="${NO}"
  typeset count=0
  typeset max_checks=30

  typeset localip=$( get_local_ip )
  while [ "${has_processed}" -eq "${NO}" ] && [ "${count}" -le "${max_checks}" ]
  do
    typeset status
    if [ "${TEST_UIM_SERVER}" == "${localip}" ]
    then
      "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${UIMnimaddress}/automated_deployment_engine" 'get_status' "${ade_jobid}" > "${TEST_TEMP}/.ade_status.data" 2>&1
      status=$( \cat "${TEST_TEMP}/.ade_status.data" )
    else
      status=$( \ssh -q ${TEST_USER_ACCESS}@${TEST_UIM_SERVER} "${TEST_PU} -u ${TEST_ADMIN} -p ${TEST_ADMIN_PWD} ${UIMnimaddress}/automated_deployment_engine get_status ${ade_jobid}" 2>&1 )
    fi
    status=$( printf "%s\n" "${status}" | \grep "Status" | \tail -n 1 | \tr -s ' ' | \cut -f 4 -d ' ' )

    #printf "%s\n" "  Current Running Status for ADE job ${ade_jobid} = ${status}"
    if [ "${status}" != "Running" ]
    then
      has_processed="${YES}"
      printf "%s\n" "${status}" >> "${TEST_RESULTS_SUBSYSTEM}/ade_job_check.data"
    fi
    sleep_func -s 5 --old-version
    count=$( increment "${count}" )
  done

  #assert_not_equals "${count}" "${max_checks}"
  [ "${has_processed}" -eq 1 ] && sleep_func -s 15 --old-version
  return "${PASS}"
}

determine_if_running_probe()
{
  if [ $# -lt 2 ]
  then
    print_no
    return "${PASS}"
  fi

  typeset probe="$1"
  shift

  typeset local_ip=$( get_local_ip )
  typeset RC

  if [ "$1" == "${local_ip}" ]
  then
    \ps -eaf | \grep nim | \grep "${probe}" >/dev/null 2>&1
    RC=$?
  else
    typeset output=$( \ssh -q ${TEST_USER_ACCESS}@$1 "\\ps -eaf | \\grep nim | \\grep probe" 2>&1 )
    RC=$?
  fi
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

get_nimaddress()
{
  return "${PASS}"
}

get_nimaddress_ip()
{
  return "${PASS}"
}

is_nimaddress()
{
  return "${PASS}"
}


# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/nim.sh"
  . "${SLCF_SHELL_TOP}/lib/nim_configuration.sh"
fi

__initialize_nim_functions
__prepared_nim_functions

