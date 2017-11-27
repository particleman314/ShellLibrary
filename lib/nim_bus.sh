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
#    __determine_number_active_probes
#    build_xml_robot_via_ade
#    deploy_robot_via_ade
#    determine_if_running_robot
#    determine_if_robot_fully_up
#    robot_setup
#    robot_teardown
#    set_hub_probes
#    set_robot_probes
#
###############################################################################

__determine_number_active_probes()
{
  typeset local_ip=$( get_local_ip )
  typeset RC
  typeset number_started_probes=0

  if [ "$1" == "${local_ip}" ]
  then
    number_started_probes=$( \ps -eaf | \grep 'nimbus' | \grep -vi 'nimsoft' | \wc -l | \sed -e 's#^ *##' | \cut -f 1 -d ' ' )
  else
    number_started_probes=$( \ssh -q ${TEST_USER_ACCESS}@$1 "\\ps -eaf | \\grep 'nimbus' | \\grep -vi 'nimsoft' | \\wc -l | \\sed -e 's#^ *##' | \\cut -f 1 -d ' '" )
  fi
  printf "%d\n" "${number_started_probes}"
  return "${PASS}"
}

__initialize_nim_bus()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_nim_functions "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
 
  __initialize "__initialize_nim_bus"

  ROBOT_PROBES='controller hdb spooler'
  HUB_PROBES='hub'
}

__prepared_nim_bus()
{
  __prepared "__prepared_nim_bus"
}

build_xml_robot_via_ade()
{
  ###
  ### Use the xmlmgt methods to generate and modify an xmlfile
  ###
  typeset input_data="$1"
  typeset reset_xml="${2:-1}"
  typeset sepchar='|'

  typeset profile=$( printf "%s\n" "${input_data}" | cut -f 1 -d "${sepchar}" )
  typeset arch=$( printf "%s\n" "${input_data}" | cut -f 2 -d "${sepchar}" )
  typeset hn=$( printf "%s\n" "${input_data}" | cut -f 3 -d "${sepchar}" )
  typeset un=$( printf "%s\n" "${input_data}" | cut -f 4 -d "${sepchar}" )
  typeset pwd=$( printf "%s\n" "${input_data}" | cut -f 5 -d "${sepchar}" )
  typeset domain=$( printf "%s\n" "${input_data}" | cut -f 6 -d "${sepchar}" )
  typeset hub=$( printf "%s\n" "${input_data}" | cut -f 7 -d "${sepchar}" )
  typeset hubrbtnm=$( printf "%s\n" "${input_data}" | cut -f 8 -d "${sepchar}" )
  typeset hubip=$( printf "%s\n" "${input_data}" | cut -f 9 -d "${sepchar}" )
  typeset rbtnm=$( printf "%s\n" "${input_data}" | cut -f 10 -d "${sepchar}" )
  typeset tmpdir=$( printf "%s\n" "${input_data}" | cut -f 11 -d "${sepchar}" )

  typeset ade_deploy_file="/tmp/ade_deploy.xml"
  [ "${reset_xml}" -eq 1 ] && [ -f "${ade_deploy_file}" ] && rm -f "${ade_deploy_file}"

  printf "%s\n" "<hosts>" >> "${ade_deploy_file}"
  printf "%s\n" "   <host>" >> "${ade_deploy_file}"
  printf "%s\n" "      <profile>${profile}</profile>" >> "${ade_deploy_file}"
  printf "%s\n" "      <arch>${arch}</arch>" >> "${ade_deploy_file}"
  printf "%s\n" "      <hostname>${hn}</hostname>" >> "${ade_deploy_file}"
  printf "%s\n" "      <username>${un}</username>" >> "${ade_deploy_file}"
  printf "%s\n" "      <password>${pwd}</password>" >> "${ade_deploy_file}"
  printf "%s\n" "      <domain>${domain}</domain>" >> "${ade_deploy_file}"
  printf "%s\n" "      <hubip>${hubip}</hubip>" >> "${ade_deploy_file}"
  printf "%s\n" "      <hub>${hub}</hub>" >> "${ade_deploy_file}"
  printf "%s\n" "      <hubrobotname>${hubrbtnm}</hubrobotname>" >> "${ade_deploy_file}"
  printf "%s\n" "      <hubport>48002</hubport>" >> "${ade_deploy_file}"
  printf "%s\n" "      <robotname>${rbtnm}</robotname>" >> "${ade_deploy_file}"
  printf "%s\n" "      <tempdir>${tmpdir}</tempdir>" >> "${ade_deploy_file}"
  printf "%s\n" "      <loglevel>3</loglevel>" >> "${ade_deploy_file}"
  printf "%s\n" "      <robotip>${hn}</robotip>" >> "${ade_deploy_file}"
  printf "%s\n" "   </host>" >> "${ade_deploy_file}"
  printf "%s\n" "</hosts>" >> "${ade_deploy_file}"

  printf "%s\n" "${ade_deploy_file}"
}

deploy_robot_via_ade()
{
  typeset ade_file=$( build_xml_robot_via_ade $@ )

  if [ -f "${ade_file}" ]
  then
    typeset UIMserver_nimaddress=$( get_nimaddress "${TEST_UIM_SERVER}" )
    [ -z "${UIMserver_nimaddress}" ] && return "${FAIL}"

    typeset nimaddress=$( get_nimaddress )
    if [ "${nimaddress}" != "${UIMserver_nimaddress}" ]
    then
      \scp "${ade_file}" ${TEST_USER_ACCESS}@${TEST_UIM_SERVER}:"${TEST_NIMROOT}/probes/service/automated_deployment_engine/host-profiles.xml" > /dev/null 2>&1
    else
      \cp "${ade_file}" "${NIMROOT}/probes/service/automated_deployment_engine/host-profiles.xml"
    fi

    sleep_func -s 15 --old-version
    run_pu_command $( get_nimaddress_ip "${UIMserver_nimaddress}" ) 'automated_deployment_engine.deploy_robot.data' "${UIMserver_nimaddress}/automated_deployment_engine" 'get_robot_deployment_job_ids' >/dev/null 2>&1

    typeset jobID=$( extract_from_pu_output ' 0' "${TEST_RESULTS_SUBSYSTEM}/automated_deployment_engine.deploy_robot.data" )

    check_ade_deployment "${jobID}" "${TEST_UIM_SERVER}"
    return $?
  else
    return "${FAIL}"
  fi
}

determine_if_running_robot()
{
  typeset local_ip=$( get_local_ip )
  typeset RC

  if [ "$1" == "${local_ip}" ]
  then
    \ps -eaf | \grep nim | \grep "controller" >/dev/null 2>&1
    RC=$?
  else
    typeset output=$( \ssh -q ${TEST_USER_ACCESS}@$1 "\\ps -eaf | \\grep nim | \\grep controller" 2>&1 )
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

determine_if_robot_fully_up()
{
  typeset local_ip=$( get_local_ip )
  typeset RC

  if [ ! -f  "${TEST_NIMROOT}/robot/controller.cfg" ]
  then
    printf "%d\n" 0
    return 1
  fi

  typeset checks=0
  if [ "$1" == "${local_ip}" ]
  then
    typeset number_expected_probes=$( \grep 'active = yes' "${TEST_NIMROOT}/robot/controller.cfg" | \wc -l | \sed -e 's#^ *##' | \cut -f 1 -d ' ' )
    typeset number_started_probes=$( __determine_number_active_probes "$1" )
    while [ "${number_started_probes}" -lt "${number_expected_probes}" ] && [ "${checks}" -lt "${maxchecks}" ]
    do
      sleep ${robot_check_interval}
      number_started_probes=$( __determine_number_active_probes "$1" )
      checks=$(( checks + 1 ))
    done
  else
    typeset number_expected_probes=$( \ssh -q ${TEST_USER_ACCESS}@$1 "grep 'active = yes' \"${TEST_NIMROOT}/robot/controller.cfg\" | wc -l | sed -e 's#^ *##' | cut -f 1 -d ' '" 2>&1 )
    typeset number_started_probes=$( __determine_number_active_probes "$1" )
    while [ "${number_started_probes}" -lt "${number_expected_probes}" ] && [ "${checks}" -lt "${maxchecks}" ]
    do
      sleep ${robot_check_interval}
      number_started_probes=$( __determine_number_active_probes "$1" )
      checks=$(( checks + 1 ))
    done
  fi

  typeset addon_sleep=0
  if [ "${checks}" -lt "${maxchecks}" ]
  then
    printf "%d\n" 1
  else
    printf "%d\n" 0
    addon_sleep=10
    sleep ${addon_sleep}
  fi

  robot_restart_time=$( printf "%s\n" "scale=0; (${robot_check_interval} * ${maxchecks} + ${addon_sleep}) * 1.2" | \bc )
  robot_check_interval=$( printf "%s\n" "scale=0; ${robot_restart_time}/${maxchecks}" | \bc );
  [ "${robot_check_interval}" -lt 3 ] && robot_check_interval=2
}

robot_setup()
{
  # set key hub_update_interval = TEST_MIN_ROBOT_RESPONSE_TIME for updates...
  typeset nimaddress=$( get_nimaddress )

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_set' "/controller" 'hub_update_interval' "${TEST_MIN_ROBOT_RESPONSE_TIME}" "''" "''" > /dev/null 2>&1

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_set' "/controller" 'os_user1' 'AUTOMATED' "''" "''" > /dev/null 2>&1

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_set' "/controller" 'os_user2' 'TESTING' "''" "''" > /dev/null 2>&1

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" '_restart' > /dev/null 2>&1
  return "${PASS}"
}

robot_teardown()
{
  # revert robot configuration and restart robot
  local localip=$( get_local_ip )

  \cp -f "${summary_path}/RESULTS/setup/${localip}_robot.cfg" "${TEST_NIMROOT}/robot/robot.cfg"

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" '_restart' > /dev/null 2>&1

  return "${PASS}"
}

set_hub_probes()
{
  return "${PASS}"
}

set_robot_probes()
{
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
fi

__initialize_nim_bus
__prepared_nim_bus
