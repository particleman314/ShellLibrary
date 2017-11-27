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
## @Software Package : Shell Automated Testing -- Parameter File Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.00
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    get_parameter_separator
#    is_color_terminal
#    load_color_map
#    load_error_definitions
#    load_parameter_file
#    query_parameter
#    set_parameter_separator
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2039,SC2120,SC2068,SC2086,SC2181,SC2119,SC2034

[ -z "${__PARAMETER_SEPARATOR}" ] && __PARAMETER_SEPARATOR=':'

__initialize_paramfilemgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"
  __initialize "__initialize_paramfilemgt"
}

__prepared_paramfilemgt()
{
  __prepared "__prepared_paramfilemgt"
}

get_parameter_separator()
{
  printf "%s\n" "${__PARAMETER_SEPARATOR}"
  return "${PASS}"
}

is_color_terminal()
{
  __debug $@
  
  typeset rval=${NO}
  
  [ "$( is_empty --str "${QUIET_MODE}" )" -eq "${YES}" ] && QUIET_MODE="${NO}"

  if [ "$( is_empty --str "${TERM}" )" -eq "${NO}" ]
  then
    case "${TERM}" in
    'xterm' )       rval="${YES}";;
    'rxvt'  )       rval="${YES}";;
    'xterm-color' ) rval="${YES}";;
    * )             rval="${YES}";;
    esac
  fi

  [ "${QUIET_MODE}" -ne "${NO}" ] && rval="${NO}"
  printf "%d\n" "${rval}"
  return "${PASS}"
}

load_color_map()
{
  __debug $@

  typeset suppress="${YES}"
  
  typeset prev_value="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  
  OPTIND=1
  while getoptex "s suppress" "$@"
  do
    case "${OPTOPT}" in
    's'|'suppress' ) suppress="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  OPTALLOW_ALL="${prev_value}"
  
  typeset rsrcpath="${1:-${SLCF_SHELL_TOP}/resources/common}"
  shift
  
  if [ -d "${rsrcpath}" ] && [ "$( is_empty --str "${DULL}" )" -eq "${YES}" ]
  then
    typeset opt=
    [ "${suppress}" -eq "${YES}" ] && opt=' --suppress'
    load_parameter_file --file "${rsrcpath}/colors.rc" ${opt}
  else
    [ "$( is_empty --str "${DULL}" )" -eq "${NO}" ] && return "${PASS}"
    return "${FAIL}"
  fi

  #########################
  # ANSI Escape Commands
  #########################
  if [ "$( is_color_terminal )" -eq "${YES}" ]
  then
ESC="\033"
NORMAL="\[$ESC[m\]"
RESET="$ESC[${DULL};${FG_WHITE};${BG_NULL}m"

BLACK="$ESC[${DULL};${FG_BLACK}m"
RED="$ESC[${DULL};${FG_RED}m"
GREEN="$ESC[${DULL};${FG_GREEN}m"
YELLOW="$ESC[${DULL};${FG_YELLOW}m"
BLUE="$ESC[${DULL};${FG_BLUE}m"
MAGENTA="$ESC[${DULL};${FG_VIOLET}m"
VIOLET=${MAGENTA}
CYAN="$ESC[${DULL};${FG_CYAN}m"
WHITE="$ESC[${DULL};${FG_WHITE}m"

BLACK_BG="$ESC[${DULL};${BG_BLACK}m"

BRIGHT_BLACK="$ESC[${BRIGHT};${FG_BLACK}m"
BRIGHT_RED="$ESC[${BRIGHT};${FG_RED}m"
BRIGHT_GREEN="$ESC[${BRIGHT};${FG_GREEN}m"
BRIGHT_YELLOW="$ESC[${BRIGHT};${FG_YELLOW}m"
BRIGHT_BLUE="$ESC[${BRIGHT};${FG_BLUE}m"
BRIGHT_MAGENTA="$ESC[${BRIGHT};${FG_VIOLET}m"
BRIGHT_VIOLET=${BRIGHT_MAGENTA}
BRIGHT_CYAN="$ESC[${BRIGHT};${FG_CYAN}m"
BRIGHT_WHITE="$ESC[${BRIGHT};${FG_WHITE}m"
  else
ESC="\033"
NORMAL="\[$ESC[m\]"
RESET="$ESC[${DULL};${FG_WHITE};${BG_NULL}m"

BLACK="${RESET}"
RED="${RESET}"
GREEN="${RESET}"
YELLOW="${RESET}"
BLUE="${RESET}"
MAGENTA="${RESET}"
VIOLET=${MAGENTA}
CYAN="${RESET}"
WHITE="${RESET}"

BRIGHT_BLACK="${RESET}"
BRIGHT_RED="${RESET}"
BRIGHT_GREEN="${RESET}"
BRIGHT_YELLOW="${RESET}"
BRIGHT_BLUE="${RESET}"
BRIGHT_MAGENTA="${RESET}"
BRIGHT_VIOLET=${BRIGHT_MAGENTA}
BRIGHT_CYAN="${RESET}"
BRIGHT_WHITE="${RESET}"
  fi
  return "${PASS}"
}

load_error_definitions()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ ${RC} -ne "${PASS}" ] && return "${FAIL}"

  #[ $( is_empty --str "${SCRIPT_PATH}" ) -eq "${YES}" ] && get_script_path > /dev/null 2>&1 

  typeset origin="${SLCF_SHELL_TOP}/resources/common"
  typeset rsrcpath="${origin}"
  typeset rsrcfile=

  typeset prev_value="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  
  OPTIND=1
  while getoptex "r: resource-dir: f: file:" "$@"
  do
    case "${OPTOPT}" in
    'r'|'resource-dir' ) rsrcpath="${OPTARG}";;
    'f'|'file'         ) rsrcfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  OPTALLOW_ALL="${prev_value}"

  [ "$( is_empty --str "${rsrcfile}" )" -eq "${YES}" ] && return "${FAIL}"
  load_parameter_file --file "${rsrcpath}/${rsrcfile}" $@
  
  return "${PASS}"
}

load_parameter_file()
{
  __debug $@
  
  typeset prmfile=
  typeset keys=
  typeset suppress="${NO}"

  OPTIND=1
  while getoptex "f: file: k: key: s suppress" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'      ) prmfile="${OPTARG}";;
    'k'|'key'       ) keys+="${OPTARG} ";;
    's'|'suppress'  ) suppress="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset k=
  for k in ${keys}
  do
    hadd_item --map 'key_retrieval' --key 'entry' --value "${k}"
  done

  typeset selected_keys="$( hget --map 'key_retrieval' --key 'entry' )"

  if [ "$( is_empty --str "${prmfile}" )" -eq "${NO}" ]
  then
    if [ -f "${prmfile}" ]
    then
      [ "${suppress}" -eq "${NO}" ] && print_plain --message "Reading file < ${prmfile} >"

      typeset param_sep="$( get_parameter_separator )"

      typeset line=
      while read -u 9 -r line
      do
        typeset allow="${NO}"
        [ "$( is_empty --str "${line}" )" -eq "${YES}" ] || [ "$( is_comment --str "${line}" )" -eq "${YES}" ] && continue
        if [ "$( is_empty --str "${selected_keys}" )" -eq "${NO}" ]
        then
          typeset key_entry=
          for key_entry in ${selected_keys}
          do
            printf "%b\n" "${line}" | \grep -q "${key_entry}"
            if [ $? -eq "${PASS}" ]
	          then
              allow="${YES}"
              break
            fi
          done
        fi

        if [ "$( is_empty --str "${selected_keys}" )" -eq "${YES}" ] || [ "${allow}" -eq "${YES}" ]
        then
          typeset key="$( trim "$( get_element --data "${line}" --id 1 --separator "${param_sep}" )" )"
          typeset value="$( trim "$(get_element --data "${line}" --id 2 --separator "${param_sep}" )" )"

          [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && continue
          
	        typeset cmd="${key}=\"${value}\""
          eval "${cmd}"
        fi
      done 9< "${prmfile}"
    else
      hclear --map 'key_retrieval'
      return "${FAIL}"
    fi
  else
    [ "$( is_empty --str "${prmfile}" )" -eq "${NO}" ] && print_plain --message "Unable to parse ${prmfile}"
    hclear --map 'key_retrieval'
    return "${FAIL}"
  fi
  hclear --map 'key_retrieval'
  return "${PASS}"
}

query_parameter()
{
  __debug $@
  
  typeset prmfile=
  typeset key=
  typeset remove_substr=
  typeset path_converter=

  typeset answer=

  OPTIND=1
  while getoptex "f: file: k: key: r. remove-str. p. path-converter." "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'           ) prmfile="${OPTARG}";;
    'k'|'key'            ) key="${OPTARG}";;
    'r'|'remove-str'     ) remove_substr="${OPTARG}";;
    'p'|'path-converter' ) path_converter="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${prmfile}" )" -eq "${YES}" ] || [ ! -f "${prmfile}" ] && return "${FAIL}"

  typeset line=
  typeset found="${NO}"

  typeset param_sep="$( get_parameter_separator )"

  while read -u 9 -r line
  do
    [ "$( is_empty --str "${line}" )" -eq "${YES}" ] || [ "$( is_comment --str "${line}" )" -eq "${YES}" ] && continue

    typeset filekey="$( get_element --data "${line}" --id 1 --separator "${param_sep}" )"
    if [ "x${filekey}" == "x${key}" ]
    then
      answer="$( get_element --data "${line}" --id 2 --separator "${param_sep}" )"
      [ "$( is_empty --str "${remove_substr}" )" -eq "${NO}" ] && answer=$( printf "%s\n" "${answer}" | \sed -e "s#${remove_substr}##g" )
      found="${YES}"
      break
    fi
  done 9< "${prmfile}"

  [ "${found}" -eq "${NO}" ] && return "${FAIL}"

  if [ "$( is_empty --str "${path_converter}" )" -eq "${NO}" ]
  then
    answer="$( make_unix_windows_path --path "$( convert_to_unc --path "${answer}" )" --style "${path_converter}" )"
  fi

  print_plain --message "${answer}"
  return "${PASS}"
}

set_parameter_separator()
{
  [ -z "$1" ] && return "${FAIL}"
  typeset chr="${1:0:1}"
  __PARAMETER_SEPARATOR="${chr}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/filemgt.sh"
fi

__initialize_paramfilemgt
__prepared_paramfilemgt
