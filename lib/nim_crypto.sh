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
#    determine_cryptographic_input
#    force_cryptographic_refresh_for_robot
#    get_cryptographic_input
#    get_cryptographic_mode
#    is_fips_enabled
#    reset_cryptographic_mode
#    set_cryptographic_input
#    set_cryptographic_mode
#
###############################################################################

__initialize_nim_crypto()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_nim_functions "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
 
  __initialize "__initialize_nim_crypto"
}

__prepared_nim_crypto()
{
  __prepared "__prepared_nim_crypto"
}

determine_cryptographic_input()
{
  [ -n "${TEST_CRYPTO_INPUT}" ] && [ -f "${TEST_CRYPTO_TEST}" ] && set_cryptographic_input "${TEST_CRYPTO_INPUT}"

  typeset crypto_file="$( get_cryptographic_input )"
  printf "%s\n" "  Using cryptographic input datafile : ${crypto_file}"
  return "${PASS}"
}

force_cryptographic_refresh_for_robot()
{
  typeset tmpfile="${TEST_TEMP}/.reset.$( \date "+%s" )"
  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_get' 'controller' '' '/controller/probe_crypto_mode' > "${tmpfile}" 2>&1

  typeset current_crypto_mode=$( extract_from_pu_output 'value' "${tmpfile}" )
  reset_cryptographic_mode "${current_crypto_mode}"
  return "${PASS}"
}

get_cryptographic_input()
{
  printf "%s\n" "${CRYPTO_INPUT_FILENAME}"
  return "${PASS}"
}

get_cryptographic_mode()
{
  typeset nimaddress="$1"
  [ -z "${nimaddress}" ] && return "${FAIL}"

  typeset tmpfile="${TEST_TEMP}/.controller_crypto_mode.$( \date "+%s" )"
  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'get_environment' 'NIM_PROBE_CRYPTO_MODE' > "${tmpfile}" 2>&1
  extract_from_pu_output 'NIM_PROBE_CRYPTO_MODE' "${tmpfile}"
  return $?
}

is_fips_enabled()
{
  typeset nimaddress="$1"

  if [ -z "${nimaddress}" ]
  then
    print_no
    return "${PASS}"
  fi

  if [ -z "${TEST_PU}" ] || [ -z "${TEST_ADMIN}" ] || [ -z "${TEST_ADMIN_PWD}" ]
  then
    print_no
    return "${PASS}"
  fi

  typeset tmpfile="${TEST_TEMP}/.status.$( date "+%s" )"
  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" '_status' 0 > "${tmpfile}" 2>&1
  typeset value=$( extract_from_pu_output 'probe_crypto_mode' "${tmpfile}" )
  [ -n "${value}" ] && print_yes
  return "${PASS}"
}

reset_cryptographic_mode()
{
  typeset nimaddress="$( get_nimaddress )"
  typeset crypto_mode="$1"

  [ -z "${nimaddress}" ] && return 1
  [ -z "${TEST_PU}" ] || [ -z "${TEST_ADMIN}" ] || [ -z "${TEST_ADMIN_PWD}" ] && return 1

  typeset nimaddress_ip=$( get_nimaddress_ip "${nimaddress}" )

  [ -z "${crypto_mode}" ] || [ "${crypto_mode}" == "''" ] && crypto_mode="${DEFAULT_CONTROLLER_CRYPTOGRAPHIC_SETTING}"

  typeset tmpfile="${TEST_TEMP}/.cfg_controller_crypto.$( \date "+%s" )"
  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_get' 'controller' '' '/controller/probe_crypto_mode' > "${tmpfile}" 2>&1
  typeset cfg_current_crypto_mode=$( extract_from_pu_output 'value' "${tmpfile}" )
  typeset env_current_crypto_mode=$( get_cryptographic_mode "${nimaddress}" )

  typeset not_env_allowed="${NO}"
  if [ -z "${env_current_crypto_mode}" ]
  then
    not_env_allowed="${YES}"
  else
    printf "%s\n" "${DEFAULT_CRYPTO_MODES}" | \tr ' ' '\n' | \grep -q "${env_current_crypto_mode}"
    typeset not_env_allowed=$?
  fi

  typeset not_cfg_allowed="${NO}"
  if [ -z "${env_current_crypto_mode}" ] || [ "${cfg_current_crypto_mode}" == "''" ]
  then
    not_cfg_allowed="${YES}"
  else
    printf "%s\n" "${DEFAULT_CRYPTO_MODES}" | \tr ' ' '\n' | \grep -q "${cfg_current_crypto_mode}"
    typeset not_cfg_allowed=$?
  fi

  printf "%s\n" "${DEFAULT_CRYPTO_MODES}" | \tr ' ' '\n' | \grep -q "${crypto_mode}"
  typeset not_rqt_allowed=$?

  if [ "${not_rqt_allowed}" -ne "${NO}" ]
  then
    if [ "${not_cfg_allowed}" -eq "${NO}" ]
    then
      crypto_mode="${cfg_current_crypto_mode}"
    else
      if [ "${not_env_allowed}" -eq "${NO}" ]
      then
        crypto_mode="${env_current_crypto_mode}"
      else
        crypto_mode="${DEFAULT_CONTROLLER_CRYPTOGRAPHIC_SETTING}"
      fi
    fi
  fi

  printf "%s\n\n" "  Reset cryptographic mode to ${crypto_mode}"

  set_cryptographic_mode "${nimaddress}" "${crypto_mode}"
  return $?
}

set_cryptographic_input()
{
  typeset inputfile="$1"

  [ -z "${inputfile}" ] || [ ! -f "${inputfile}" ] && return "${FAIL}"
  CRYPTO_INPUT_FILENAME="${inputfile}"
  return "${PASS}"
}

set_cryptographic_mode()
{
  typeset nimaddress="$1"
  typeset crypto_mode="$2"

  [ -z "${nimaddress}" ] && return "${FAIL}"
  [ -z "${TEST_PU}" ] || [ -z "${TEST_ADMIN}" ] || [ -z "${TEST_ADMIN_PWD}" ] && return "${FAIL}"

  typeset nimaddress_ip=$( get_nimaddress_ip "${nimaddress}" )

  [ -z "${crypto_mode}" ] && crypto_mode="${DEFAULT_CONTROLLER_CRYPTOGRAPHIC_SETTING}"

  typeset current_crypto_mode=$( get_cryptographic_mode "${nimaddress}" )
  if [ -n "${current_crypto_mode}" ] && [ "${current_crypto_mode}" == "${crypto_mode}" ]
  then
    "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_set' 'controller' "/controller" 'probe_crypto_mode' "${crypto_mode}" "''" "''" > /dev/null 2>&1
    "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" '_restart' > /dev/null 2>&1
    return "${PASS}"
  fi

  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" 'probe_config_set' 'controller' "/controller" 'probe_crypto_mode' "${crypto_mode}" "''" "''" > /dev/null 2>&1
  "${TEST_PU}" -u "${TEST_ADMIN}" -p "${TEST_ADMIN_PWD}" "${nimaddress}/controller" '_stop' > /dev/null 2>&1

  typeset running_probes=$(__determine_number_active_probes "${nimaddress_ip}" )
  while [ "${running_probes}" -gt 2 ]
  do
    sleep_func -s 1 --old-version
    running_probes=$(__determine_number_active_probes "${nimaddress_ip}" )
  done

  rm -f "${TEST_NIMROOT}/robot/controller.log"

  typeset robot_running=$( determine_if_robot_fully_up "${nimaddress_ip}" )
  if [ "${robot_running}" -ne "${YES}" ]
  then
    printf "%s\n" "Robot did NOT come back up as expected"
    return
  fi

  typeset has_hub=$( determine_if_running_hub "${nimaddress_ip}" )
  if [ "${has_hub}" -eq "${YES}" ]
  then
    typeset hub_running="${NO}"
    while [ "${hub_running}" -eq "${NO}" ]
    do
      sleep_func -s 15 --old-version
      hub_running=$( determine_if_running_hub "${nimaddress_ip}" )
    done
  fi
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/nim_functions.sh"
fi

__initialize_nim_crypto
__prepared_nim_crypto

