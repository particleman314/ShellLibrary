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
## @Software Package : Shell Automated Testing -- Docker Manipulation
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.01
#
###############################################################################

###############################################################################
#
# Functions Supplied :
#
#    __define_docker_network_interface
#    __get_container_data
#    determine_container_ports
#    determine_container_volumes
#    get_container
#    get_logs_from_container
#    has_docker_compose
#    send_command_to_container
#    start_container
#    stop_container
#
###############################################################################

if [ -z "${__DOCKER_NETWORK_INTERFACE}" ]
then
  __DOCKER_NETWORK_INTERFACE='docker0'
fi

__initialize_docker_containers()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  __load __initialize_base_logging "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/jsonmgt.sh"
  __load __initialize_execaching "${SLCF_SHELL_TOP}/lib/execaching.sh"

  make_executable --exe 'docker'
  [ $? -ne "${PASS}" ] return "${FAIL}"

  make_executable --exe 'docker-compose' --alias 'dockercompose'

  __initialize "__initialize_docker_containers"
}

__prepared_docker_containers()
{
  __prepared "__prepared_docker_containers"
}

__define_docker_network_interface()
{
  __debug $@

  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"

  __DOCKER_NETWORK_INTERFACE="${input}"
  return "${PASS}"
}

__get_container_data()
{
  __debug $@

  typeset data=
  typeset field=
  typeset search=

  OPTIND=1
  while getoptex "data: field: search:" "$@"
  do
    case "${OPTOPT}" in
    'data'      ) data="${OPTARG}";;
    'field'     ) field="${OPTARG}";;
    'search'    ) search="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))    

  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${field}" ] && return "${FAIL}"

  typeset match="$( printf "%s\n" "$( ${docker_exe} 'ps' --format "{{.${search}}}|{{.${field}}" )" | \grep "^${data}" )"
  [ "$( is_empty --str "${match}" )" -eq "${NO}" ] && printf "%s\n" "${match}" | \cut -f 2 -d '|'

  return "${PASS}"

}

get_container()
{
  __debug $@

  typeset attr=
  typeset data=
  typeset field=

  OPTIND=1
  while getoptex "a: attr: attribute: data: field:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'attr'|'attribute'   ) attr="${OPTARG}";;
               'data'        ) data="${OPTARG}";;
               'field'       ) field="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))    

  [ -z "${attr}" ] && return "${FAIL}"
  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${attr}" ] && attr='ID'

  __get_container_data --data "${data}" --field "${field}" --search "${attr}"
  return $?
}

get_logs_from_container()
{
  typeset attr=
  typeset data=

  OPTIND=1
  while getoptex "a: attr: attribute: data:" "$@"
  do
    case "${OPTOPT}" in
    'data'   ) data="${OPTARG}";;
    'attr'   ) attr="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))    

  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${attr}" ] && attr='ID'
  
  typeset container_id="$( __get_container_data --data "${data}" --field 'ID' --search "${attr}" )"
  ${docker_exe} logs ${container_id}
  return $?
}

has_docker_compose()
{
  __debug $@

  is_empty --str "${dockercompose_exe}"
  return "${PASS}"
}

start_container()
{
  __debug $@
}

stop_container()
{
  __debug $@
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/hashmaps.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/jsonmgt.sh"
fi

__initialize_docker_containers
[ $? -ne 0 ] && exit 1

__prepared_docker_containers

