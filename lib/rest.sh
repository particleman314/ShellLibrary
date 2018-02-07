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
## @Software Package : Shell Automated Testing -- REST API Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.41
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_rest_address
#    __get_rest_address_port
#    __set_rest_address
#    __set_rest_address_port
#    run_rest_api
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2181

[ -z "${__RESTAPI_MAP}" ] && __RESTAPI_MAP=

__get_rest_api_address()
{
  typeset restname="$1"
  [ "$( is_empty --str "${restname}" )" -eq "${YES}" ] && return "${FAIL}"
 
  typeset addr="$( hget --map '__RESTAPI_MAP' --key "webaddress_${restname}" )"
  typeset RC=$?
  
  if [ "$( is_empty --str "${addr}" )" -eq "${NO}" ] && [ "${RC}" -eq "${PASS}" ]
  then
    typeset cfgport="$( hget --map '__RESTAPI_MAP' --key "port_${restname}" )"
    RC=$?

    [ "$( is_empty --str "${cfgport}" )" -eq "${NO}" ] && addr+=":${cfgport}"
    printf "%s\n" "${addr}"
  else
    RC="${FAIL}"
  fi
  
  return "${RC}"
}

__get_rest_api_address_port()
{
  typeset restname="$1"
  [ "$( is_empty --str "${restname}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset output="$( hget --map '__RESTAPI_MAP' --key "port_${restname}" )"
  typeset RC=$?
  
  if [ -n "${output}" ]
  then
    printf "%s\n" "${output}"
  else
    RC="${FAIL}"
  fi
  return "${RC}"
}

__initialize_rest()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_networkmgt "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  __load __initialize_xmlmgt "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
  __load __initialize_jsonmgt "${SLCF_SHELL_TOP}/lib/jsonmgt.sh"
  __load __initialize_machinemgt "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  __load __initialize_logging "${SLCF_SHELL_TOP}/lib/logging.sh"
  __load __initialize_hashmaps "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  __load __initialize_passwordmgt "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"

  manage_executables 'curl' 'wget'
  typeset RC=$?

  __initialize "__initialize_rest"
  return "${RC}"
}

__prepared_rest()
{
  __prepared "__prepared_rest"
}

__set_rest_api_address()
{
  typeset restname="$1"
  typeset addr="$2"
  shift 2

  [ "$( is_empty --str "${restname}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ "$( is_empty --str "${addr}" )" -eq "${YES}" ]
  then
    hdel --map '__RESTAPI_MAP' --key "webaddress_${restname}"
  else
    hput --map '__RESTAPI_MAP' --key "webaddress_${restname}" --value "${addr}"
  fi
  return $?
}

__set_rest_api_address_port()
{
  typeset restname="$1"
  typeset port="$2"
  shift
  
  [ "$( is_empty --str "${restname}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ "$( is_empty --str "${port}" )" -eq "${YES}" ]
  then
    hdel --map '__RESTAPI_MAP' --key "port_${restname}"
    return $?
  elif [ "$( is_numeric_data --data "${port}" )" -eq "${NO}" ]
  then
    #print_msg --channel ERROR --message "Non numeric data for port discovered.  Skipping!"
    return "${FAIL}"
  else
    if [ "${port}" -gt 0 ] && [ "${port}" -lt 65536 ]
    then
      hput --map '__RESTAPI_MAP' --key "port_${restname}" --value "${port}"
      return $?
    else
      #print_msg --channel ERROR --message "Port selected is not in applicable range [ 0-65535 ]"
      return "${FAIL}"
    fi
  fi
}

delete_rest_api_db()
{
  __debug $@

  typeset map_subsection=
  typeset key=
  typeset clear_db="${NO}"

  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'  ) map_subsection="${OPTARG}";;
    'k'|'key'  ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map_subsection}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && clear_db="${YES}"

  typeset subsections="$( hget --map '__RESTAPI_MAP' --key 'subsections' )"
  [ -z "${subsections}" ] && return "${FAIL}"

  typeset ss=
  for ss in ${subsections}
  do
    if [ "${ss}" == "${map_subsection}" ]
    then
      if [ "${clear_db}" -eq "${YES}" ]
      then
        hclear --map "${ss}"
      else
        hdel --map "${ss}" --key "${key}"
      fi
      return $?
    fi
  done
  return "${FAIL}"
}

get_rest_api_db()
{
  __debug $@

  typeset map_subsection=
  typeset key=

  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'  ) map_subsection="${OPTARG}";;
    'k'|'key'  ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map_subsection}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset subsections="$( hget --map '__RESTAPI_MAP' --key 'subsections' )"
  [ -z "${subsections}" ] && return "${FAIL}"

  typeset ss=
  for ss in ${subsections}
  do
    if [ "${ss}" == "${map_subsection}" ]
    then
      hget --map "${ss}" --key "${key}"
      return $?
    fi
  done
  return "${FAIL}"
}

set_rest_api_db()
{
  __debug $@

  typeset map_subsection=
  typeset key=
  typeset val=
  typeset append="${NO}"

  OPTIND=1
  while getoptex "m: map: k: key: v: value: a append" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'    ) map_subsection="${OPTARG}";;
    'k'|'key'    ) key="${OPTARG}";;
    'v'|'value'  ) val="${OPTARG}";;
    'a'|'append' ) append="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map_subsection}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${val}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset subsections="$( hget --map '__RESTAPI_MAP' --key 'subsections' )"

  typeset ss=
  for ss in ${subsections}
  do
    if [ "${ss}" == "${map_subsection}" ]
    then
      if [ "${append}" -eq "${YES}" ]
      then
        hadd_item --map "${ss}" --key "${key}" --value "${val}"
      else
        hput --map "${ss}" --key "${key}" --value "${val}"
      fi
      return $?
    fi
  done

  hput --map "${map_subsection}" --key "${key}" --value "${val}"
  hadd_item --map '__RESTAPI_MAP' --key 'subsections' --value "${map_subsection}" --unique
  return "${PASS}"
}

run_rest_api()
{
  typeset prevopt="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"

  typeset user_id=
  typeset passwd=
  typeset restcmd=
  typeset passwd_decode="${NO}"
  typeset restmapname=
  
  OPTIND=1
  while getoptex "c: cmd: command: u: user-id: p: passwd: d decode resttype:" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user-id'       ) user_id="${OPTARG}";;
    'p'|'passwd'        ) passwd="${OPTARG}";;
    'c'|'cmd'|'command' ) restcmd="${OPTARG}";;
    'd'|'decode'        ) passwd_decode="${YES}";;
        'resttype'      ) restmapname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  OPTALLOW_ALL="${prevopt}"

  [ "$( is_empty --str "${user_id}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${restcmd}" )" -eq "${YES}" ] && return "${FAIL}"
  
  [ "${passwd_decode}" -eq "${YES}" ] && passwd="$( decode_passwd "${passwd}" )"
  
  [ "$( is_empty --str "${restmapname}" )" -eq "${NO}" ] && cmd="$( __get_rest_api_address "${restmapname}" )/${cmd}"
  
  typeset outfile="$( make_output_file --channel 'CURL_OUTPUT' )"
  typeset fullcmd="${curl_exe} -s -L -u ${user_id}:${passwd} $@ ${cmd} -o ${outfile}"
  
  append_output --channel 'CMD' --data "${fullcmd}"
  eval "${fullcmd}"
  typeset RC=$?
  
  typeset output=$( \cat "${outfile}" )
  if [ "${RC}" -ne "${PASS}" ]
  then
    append_output --channel 'ERROR' --data "Unable to successfully run CURL command ( RC = ${RC} ):"
    append_output --channel 'ERROR '--data "${output}"
  else
    printf "%s\n" "${output}"
  fi
  
  remove_output_file --channel 'CURL_OUTPUT'
  
  return "${RC}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/logging.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/jsonmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
fi

__initialize_rest
[ $? -ne "${PASS}" ] && exit "${FAIL}"

__prepared_rest
