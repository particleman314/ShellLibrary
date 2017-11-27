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
#    __verify_command_exists
#    deploy_probe_via_ade
#    restore_probe_configfile
#    save_probe_configfile
#    verify_command_exists
#
###############################################################################

__initialize_nim_probe()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_nim_functions "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
 
  __initialize "__initialize_nim_probe"
}

__prepared_nim_probe()
{
  __prepared "__prepared_nim_probe"
}

__verify_command_exists()
{
  typeset probe="$1"
  typeset cmd="$2"
  typeset nimaddress="$3"

  if [ -z "${probe}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset nimaddress_ip=
  typeset localip=$( get_local_ip )

  if [ -z "${nimaddress}" ]
  then
    nimaddress_ip="${localip}"
  else
    nimaddress_ip=$( get_nimaddress_ip "${nimaddress}" )
  fi

  typeset output
  typeset detail="${NO}"

  typeset now=$( __today_as_seconds )
  typeset tmpfile="${summary_path}/.command_check_${now}"

  if [ "${nimaddress_ip}" == "${localip}" ]
  then
    output=$( "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}" '_command' ${detail} 2>&1 )
  else
    output=$( \ssh ${TEST_USER_ACCESS}@${ip} "${TEST_PU} -u ${TEST_ADMIN} -p ${TEST_ADMIN_PWD} ${nimaddress} _command ${detail} 2>&1" )
  fi

  printf "%s\n" "${output}" > "${tmpfile}"
  \grep -q "${cmd}" "${tmpfile}"
  if [ $? -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi

  \rm -f "${tmpfile}"
  return "${PASS}"
}

deploy_probe_via_ade()
{
  typeset probe_id="$1"
  typeset probe_version="$2"

  [ -z "${probe_id}" ] || [ "${probe_id}" == "''" ] && return "${FAIL}"
  [ -z "${probe_version}" ] && probe_version="''"

  typeset UIMserver_nimaddress=$( get_nimaddress "${TEST_UIM_SERVER}" )
  [ -z "${UIMserver_nimaddress}" ] && return "${FAIL}"

  typeset nimaddress=$( get_nimaddress )

  run_pu_command $( get_nimaddress_ip "${UIMserver_nimaddress}" ) 'automated_deployment_engine.deploy_probe.data' "${UIMserver_nimaddress}/automated_deployment_engine" 'deploy_probe' "${probe_id}" "${probe_version}" "${nimaddress}" >/dev/null 2>&1
  [ $? -ne "${PASS}" ] && return "${FAIL}"

  typeset jobID=$( extract_from_pu_output 'JobID' "${TEST_RESULTS_SUBSYSTEM}/automated_deployment_engine.deploy_probe.data" )

  #printf "%s\n" "  Checking JobID = ${jobID} for ${probe_id}|${probe_version}"
  check_ade_deployment "${jobID}" "${TEST_UIM_SERVER}"
  return $?
}

restore_probe_configfile()
{
  typeset ip="$1"
  typeset probe_id="$2"
  typeset probe_location="$3"

  [ -z "${ip}" ] || [ -z "${probe_id}" ] || [ -z "${probe_location}" ] && return "${FAIL}"

  typeset localip=$( get_local_ip )
  if [ "${ip}" == "${localip}" ]
  then
    \cp -f "${summary_path}/RESULTS/setup/${probe_id}.cfg.orig" "${TEST_NIMROOT}/${probe_location}/${probe_id}.cfg"
    "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/${probe_id}" '_restart' > /dev/null 2>&1
  else
    \ssh -q ${TEST_USER_ACCESS}@${ip} "cp -f \"${summary_path}/RESULTS/setup/${probe_id}.cfg.orig\" \"${TEST_NIMROOT}/${probe_location}/${probe_id}.cfg\"" > /dev/null 2>&1
    \ssh -q ${TEST_USER_ACCESS}@${ip} "\"${TEST_PU}\" -u \"${TEST_ADMIN}\" -p \"${TEST_ADMIN_PWD}\" \"${nimaddress}/${probe_id}\" '_restart' > /dev/null 2>&1" > /dev/null 2>&1
  fi

  return "${PASS}"
}

save_probe_configfile()
{
  typeset ip="$1"
  typeset probe_id="$2"
  typeset probe_location="$3"
  [ -z "${ip}" ] || [ -z "${probe_id}" ] || [ -z "${probe_location}" ] && return "${FAIL}"

  typeset localip=$( get_local_ip )
  if [ "${ip}" == "${localip}" ]
  then
    \cp -f "${TEST_NIMROOT}/${probe_location}/${probe_id}.cfg" "${summary_path}/RESULTS/setup/${probe_id}.cfg.orig"
  else
    \ssh -q ${TEST_USER_ACCESS}@${ip} "cp -f \"${TEST_NIMROOT}/${probe_location}/${probe_id}.cfg\" \"${summary_path}/RESULTS/setup/${probe_id}.cfg.orig\"" > /dev/null 2>&1
  fi
  return $?
}

verify_command_exists()
{
  typeset result=$( __verify_command_exists $@ )
  typeset RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
  else
  	printf "%d\n" "${result}"
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
fi

__initialize_nim_probe
__prepared_nim_probe

