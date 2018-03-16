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
## @Software Package : Shell Automated Testing -- Executable Caching
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.11
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    check_for_cmd_in_path
#    get_exe
#    in_path
#    make_executable
#    manage_executables
#
###############################################################################

# shellcheck disable=SC2016,SC2068,SC2039,SC1117,SC2181

NO_EXECUTABLE_IN_PATH=10

__initialize_execaching()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  __load __initialize_base_machinemgt "${SLCF_SHELL_TOP}/lib/base_machinemgt.sh"
  __initialize "__initialize_execaching"
}

__prepared_execaching()
{
  __prepared "__prepared_execaching"
}

check_for_cmd_in_path() 
{
  __debug $@
  
  typeset RC=${FAIL}
  typeset var="$1"
  
  if [ -n "${var}" ]
  then
    if [ "${var%${var#?}}" = "/" ]
    then
      [ ! -x "${var}" ] && return "${FAIL}"
    else
      in_path "${var}" "${PATH}"
      RC=$?
      [ "${RC}" -eq "${NO}" ] && return "${FAIL}"
    fi
  fi
  return "${PASS}"
}

get_exe() 
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset exe_name=
  typeset path_hint=
  typeset ext_hint=
  typeset system_cmd="${NO}"

  OPTIND=1
  while getoptex "c: p. e. s exename: path. extension_list. syscmd" "$@"
  do
    case "${OPTOPT}" in
    'c'|'exename'        ) exe_name="${OPTARG}";;
    'p'|'path'           ) path_hint="${OPTARG}";;
    'e'|'extension_list' ) ext_hint+="|${OPTARG}";;
    's'|'syscmd'         ) system_cmd="${YES}";;
    esac
  done
  shift $(( OPTIND -1 ))
  
  [ "$( is_empty --str "${exe_name}" )" -eq "${YES}" ] && return "${FAIL}"
 
  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    if [ -z "${ext_hint}" ]
    then
      ext_hint='.exe'
    else
      ext_hint=".exe${ext_hint}"
    fi
  fi
  
  if [ "$( is_empty --str "${path_hint}" )" -eq "${NO}" ]
  then
    typeset count="$( __get_word_count "${ext_hint}" )"
    while [ "${count}" -ge 0 ]
    do
      typeset extension=
      if [ "${count}" -ne 0 ]
      then
        extension="$( next_in_sequence --id "${count}" --data "${ext_hint}" --separator '|' )"
      fi
      if [ -e "${path_hint}/${exe_name}${extension}" ]
      then
        print_plain --message "${path_hint}/${exe_name}${extension}" --format "%s"
        return "${PASS}"
      fi
      count=$(( count - 1 ))
    done
  fi

  RC="${PASS}"
  typeset exe="${exe_name}"

  typeset expanded_ext_hist=
  [ -n "${ext_hint}" ] && expanded_ext_hist="$( printf "%s\n" "${ext_hint}" | \tr '|' ' ' )"
  
  typeset count="$( __get_word_count "${expanded_ext_hist}" )"
  while [ "${count}" -ge 0 ]
  do
    typeset extension
    if [ "${count}" -ne 0 ]
    then
      extension="$( next_in_sequence --id "${count}" --data "${ext_hint}" --separator '|' )"
    fi
    check_for_cmd_in_path "${exe_name}${extension}"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      exe="$( \which "${exe_name}${extension}" 2>&1 )"
      RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
        exe="$( type "${exe_name}${extension}" )"
        RC=$?
      fi
      [ "${RC}" -eq "${PASS}" ] && break
    else
      RC="${FAIL}"
    fi
    count=$(( count - 1 ))
  done

  [ "${RC}" -eq "${PASS}" ] && print_plain --message "${exe}"

  return "${RC}"
}

in_path()
{
  __debug $@
  
  typeset cmd=$1
  typeset path="${2:-${PATH}}"
  
  typeset RC="${NO}"
 
  [ -z "${cmd}" ] && return "${RC}"

  typeset oldIFS="${IFS}"
  IFS=":"
 
  typeset directory=
  for directory in ${path}
  do
    if [ -x "${directory}/${cmd}" ]
    then
      __debug "Checking directory <${directory}> for command <${cmd}>"
      RC="${YES}"
      break
    fi
  done
  
  IFS="${oldIFS}"
  return "${RC}"
}

make_executable()
{
  __debug $@
  
  typeset exe=
  typeset exe_alias=

  typeset prev_value="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
 
  OPTIND=1
  while getoptex "e: exe: a: alias:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'exe'    ) exe="${OPTARG}";;
    'a'|'alias'  ) exe_alias="${OPTARG}";;
    esac
  done
  shift $(( OPTIND - 1 ))
  
  OPTALLOW_ALL="${prev_value}"

  [ "$( is_empty --str "${exe}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${exe_alias}" )" -eq "${YES}" ] && exe_alias="${exe}"

  typeset checkcmd=
  eval "checkcmd=\"\${${exe_alias}_exe}\""
  
  [ "$( is_empty --str "${checkcmd}" )" -eq "${NO}" ] && return "${PASS}"
  
  typeset cmd="${exe_alias}_exe=\$( get_exe -c ${exe} $* )"
  eval "${cmd}"

  eval "checkcmd=\"\${${exe_alias}_exe}\""

  if [ "$( is_empty --str "${checkcmd}" )" -eq "${YES}" ]
  then
    __debug "Unable to find executable for < ${exe} > in PATH env!"
    return "${FAIL}"
  fi
  
  cmd="${exe_alias}_exe=\${checkcmd}"
  eval "${cmd}"
 
  return "${PASS}"
}

manage_executables()
{
  __debug $@

  typeset suppress="${NO}"
  
  OPTIND=1
  while getoptex "s suppress" "$@"
  do
    case "${OPTOPT}" in
    's'|'suppress' ) suppress="${YES}";;
    esac
  done
  shift $(( OPTIND -1 ))
  
  typeset entries=$*
  for e in ${entries}
  do
    typeset required="$( trim "$( get_element --data "${e}" --id 1 --separator '|' )" )"
    typeset replacement="$( trim "$( get_element --data "${e}" --id 2 --separator '|' )" )"

    [ "$( is_empty --str "${replacement}" )" -eq "${YES}" ] && replacement="${required}"

    typeset cmd_old="${required}_exe"
    typeset interpret
    eval "interpret=\${${cmd_old}}"

    if [ "$( is_empty --str "${interpret}" )" -eq "${YES}" ]
    then
      
      make_executable --exe "${replacement}" --syscmd
      typeset RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
	      [ "${suppress}" -eq "${NO}" ] && print_plain --message "Unable to find substitute executable <${replacement}> for <${required}>"
	      return "${NO_EXECUTABLE_IN_PATH}"
      fi
      cmd="${required}_exe=\${${replacement}_exe}"
      eval "${cmd}"
    fi
  done
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/base_machinemgt.sh"
fi
__initialize_execaching
__prepared_execaching
