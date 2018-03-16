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
## @Software Package : Shell Automated Testing -- Log Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.03
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __set_log_marker_width
#    print_debug_msg
#    print_msg
#    print_std_failure
#    print_std_success
#
###############################################################################

# shellcheck disable=SC2016,SC2068,SC2039,SC2086,SC2089,SC2090,SC2181

[ -z "${__LOG_MARKER_WIDTH}" ] && __LOG_MARKER_WIDTH=7

__initialize_logging()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"
  __load __initialize_paramfilemgt "${SLCF_SHELL_TOP}/lib/paramfilemgt.sh"

  __initialize "__initialize_logging"
}

__prepared_logging()
{
  __prepared "__prepared_logging"
}

__set_log_marker_width()
{
  __debug $@

  [ -z "$1" ] || [ "$( is_numeric_data --data "$1" )" -eq "${NO}" ] && return "${FAIL}"
  [ "$1" -le 0 ] && return "${FAIL}"

  __LOG_MARKER_WIDTH="$1"

  return "${PASS}"
}

print_debug_msg()
{
  __debug $@
 
  if [ -n "${USE_COLOR_MAP}" ] && [ "${USE_COLOR_MAP}" -eq "${YES}" ]
  then
    [ -z "${BRIGHT_MAGENTA}" ] && load_color_map --suppress
  fi

  typeset msg=
  typeset color=${BRIGHT_MAGENTA}
  typeset suppress="${NO}"
  typeset fullscreen="${NO}"
  typeset channels
  
  OPTIND=1
  while getoptex "channel: color: m: message: x. suppress. fullscreen." "$@"
  do
    case "${OPTOPT}" in
        'color'      ) color="${OPTARG}";;
    'm'|'message'    ) msg="${OPTARG}";;
    'x'|'suppress'   ) suppress=${YES};;
        'fullscreen' ) fullscreen=${YES};;
        'channel'    ) channels+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${DEBUGGING}" ] || [ "${DEBUGGING}" -ne "${YES}" ] || [ ${suppress} -eq "${YES}" ] && return "${PASS}"

  [ "$( is_empty --str "${channels}" )" -eq "${YES}" ] && channels='STDOUT'

  typeset channel_args=
  typeset c=
  for c in ${channels}
  do
    channels+=" --channel \"${c}\""
  done

  typeset extrainfo="$( get_verbosity_info )"
  typeset identifier="$( center_text --text "DEBUG" --width "${__LOG_MARKER_WIDTH}" )"
  while [ "${#identifier}" -lt "${__LOG_MARKER_WIDTH}" ]
  do
    identifier="${identifier} "
  done

  typeset fullmsg=
  
  if [ "${fullscreen}" -eq "${NO}" ]
  then
    if [ "$( is_empty --str "${extrainfo}" )" -eq "${NO}" ]
    then
      fullmsg="${color}[ ${identifier} | ${extrainfo} ]${RESET} ${msg}"
    else
      fullmsg="${color}[ ${identifier} ]${RESET} ${msg}"
    fi
  else
    typeset availwidth=$(( COLUMNS - 4 - ${#identifier} - 4 ))
    typeset msgwidth="${#msg}"
	
    msg="${msg:0:${availwidth}}"
	
    [ "${msgwidth}" -gt "${availwidth}" ] && msg="${msg}..."
	
    fullmsg="$( print_plain --format "%.${availwidth}s" --message "${msg}" )"
    fullmsg="${fullmsg} ${color}[ ${identifier} ]${RESET}"
  fi

  append_output --data "${fullmsg}" ${channel_args}
  sync
  return "${PASS}"
}

print_msg()
{
  __debug $@

  if [ -n "${USE_COLOR_MAP}" ] && [ "${USE_COLOR_MAP}" -eq "${YES}" ]
  then
    [ -z "${BRIGHT_MAGENTA}" ] && load_color_map --suppress
  fi
  
  typeset color="${BLACK_BG}${BRIGHT_CYAN}"
  typeset suppress="${NO}"
  typeset caption

  [ "$( is_empty --str "${SUPPRESS_OUTPUT_TO_TERMINAL}" )" -eq "${NO}" ] && [ "${SUPPRESS_OUTPUT_TO_TERMINAL}" -ne "${NO}" ] && suppress="${YES}"

  typeset msg=
  typeset msgtype="INFO"
  typeset funcname=
  typeset errorcode="${PASS}"
  typeset fullscreen="${NO}"
  typeset channels=
  
  OPTIND=1
  while getoptex "c; color; e. error-code. errorcode. f. m: msg: message: channel: t. type. x suppress fullscreen" "$@"
  do
    case "${OPTOPT}" in
        'color'                      )     color="${OPTARG}";;
    'e'|'error-code'|'errorcode'     )     errorcode="${OPTARG}";;
    'f'|'funcname'                   )     funcname="${FUNCNAME}[0]";;
    'm'|'msg'|'message'              )     msg="${OPTARG}";;
    't'|'type'                       )     msgtype="${OPTARG}";;
    'x'|'suppress'                   )     suppress="${YES}";;
        'channel'                    )     channels+=" ${OPTARG}";;
	      'fullscreen'                 )     fullscreen="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${msg}" )" -eq "${YES}" ] && return "${PASS}"
  [ "${suppress}" -eq "${YES}" ] && return "${PASS}"

  [ "$( is_empty --str "${channels}" )" -eq "${YES}" ] && channels='STDOUT'

  typeset channel_args=
  typeset c=
  for c in ${channels}
  do
    channel_args=" --channel ${c}"
  done

  case "${msgtype}" in
  'DEBUG'    )
     color="${BLACK_BG}${BRIGHT_MAGENTA}";
     if [ "${fullscreen}" -eq "${YES}" ]
     then
       print_debug_msg -m "${msg}" --color "${color}" --fullscreen ${channel_args}
     else
       print_debug_msg -m "${msg}" --color "${color}" ${channel_args}
     fi
     return $?
  ;;
  'WARNING'|'WARN' )
     color="${BLACK_BG}${BRIGHT_YELLOW}";
     caption="WARNING"
   ;;
  'ERROR'|'CRITICAL'|'FATAL'|'FAILURE'|'FAILED'|'FAIL'   )
     color="${BLACK_BG}${BRIGHT_RED}";
     caption="${msgtype}"
   ;;
  'SUCCESS'|'PASS'|'PASSED'   )
     color="${BLACK_BG}${BRIGHT_GREEN}";
     caption="${msgtype}"
   ;;
  * )
     caption="${msgtype}"
   ;;
  esac

  typeset extrainfo="$( get_verbosity_info )"
  typeset identifier="$( center_text --text "${caption}" --width "${__LOG_MARKER_WIDTH}" )"

  while [ "${#identifier}" -lt "${__LOG_MARKER_WIDTH}" ]
  do
    identifier="${identifier} "
  done

  typeset nocolor="${NO}"

  if [ -n "${QUIET_MODE}" ] && [ "${QUIET_MODE}" -eq "${YES}" ]
  then
    nocolor="${YES}"
    color=
  fi
  [ "$( is_empty --str "${funcname}" )" -eq "${NO}" ] && funcname="{${funcname}}"

  typeset fullmsg=
  if [ "${fullscreen}" -eq "${NO}" ]
  then
    fullmsg="${color}[ ${identifier}"
    if [ "$( is_empty --str "${extrainfo}" )" -ne "${YES}" ]
    then
      fullmsg="${fullmsg} | ${extrainfo} ]${RESET} ${msg}"
    else
      fullmsg="${fullmsg} ]${RESET} ${msg}"
    fi
    [ "x${msgtype}" == "xERROR" ] && [ "${errorcode}" -ne "${PASS}" ] && fullmsg="${fullmsg} :: ERROR_CODE = ${errorcode}"
    #fullmsg="${fullmsg} :: ERROR_CODE = ${errorcode}"
  else
    typeset availwidth=$(( COLUMNS - 4 - ${#identifier} - 4 ))
    typeset msgwidth="${#msg}"
	
    msg="${msg:0:${availwidth}}"

    [ "${msgwidth}" -gt "${availwidth}" ] && msg="${msg}..."
	
    fullmsg="$( print_plain --format "%.${availwidth}s" --message "${msg}" )"
    fullmsg="${fullmsg} ${color}[ ${identifier} ]${RESET}"
  fi

  append_output_tee --data "${fullmsg}" ${channel_args}
  sync
  return "${PASS}"
}

print_std_failure()
{
  typeset errorcode=-1

  OPTIND=1
  while getoptex "e. error-code. m: message: t. type." "$@"
  do
    case "${OPTOPT}" in
    'e'|'error-code' )  errorcode="${OPTARG}";;
    'm'|'message'    )  msg="${OPTARG}";;
    't'|'type'       )  msgtype="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${errorcode}" != '-1' ] && errorcode="--error-code ${errorcode}"

  print_msg ${errorcode} --message "${msg}" --type 'FAILURE'
  return $?
}

print_std_success()
{
  typeset errorcode=-1

  OPTIND=1
  while getoptex "e. error-code. m: message: t. type." "$@"
  do
    case "${OPTOPT}" in
    'e'|'error-code' )  errorcode="${OPTARG}";;
    'm'|'message'    )  msg="${OPTARG}";;
    't'|'type'       )  msgtype="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${errorcode}" != '-1' ] && errorcode="--error-code ${errorcode}"

  print_msg ${errorcode} --message "${msg}" --type 'SUCCESS'
  return $?
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/numerics.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/paramfilemgt.sh"
fi

__initialize_logging
__prepared_logging
