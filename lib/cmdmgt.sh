#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2017.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Local Command Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.04
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __queue_cmd
#    __reset_cmd_stats
#    __store_command
#    __store_command_rc
#    __update_channel_list
#    disable_cmd_recording
#    enable_cmd_recording
#    get_last_cmd
#    get_last_cmd_code
#    get_last_cmd_id
#    issue_cmd
#    record_cmd
#    record_cmd_output
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2068,SC2086

if [ -z "${__CMD_LAST_RC}" ]
then
  __CMD_RECORD_CHANNEL='ISSUE_CMD'
  __CMD_STORE_MAP='storecmd'
  __CMD_STORE_MAP_FILE=
  __CMDMGT_NEWLINE_MARKER='__++__'

  __LOCAL_Q_COMMANDS=
fi

__initialize_cmdmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )
  
  __load __initialize_data_structures "${SLCF_SHELL_TOP}/lib/data_structures.sh"
  __load __initialize_cmd_interface "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"

  if [ "$( is_channel_in_use --channel "${__CMD_RECORD_CHANNEL}" )" -eq "${NO}" ]
  then
    __ALLOW_CMD_RECORDING="${YES}"
    make_output_file --channel "${__CMD_RECORD_CHANNEL}" --unique >/dev/null 2>&1
    make_output_file --channel 'STORE_CMD' --unique > /dev/null 2>&1

    mark_channel_persistent --channel 'STORE_CMD'
    __CMD_STORE_MAP_FILE="$( find_output_file --channel 'STORE_CMD' )"
  fi

  __initialize "__initialize_cmdmgt"
}

__prepared_cmdmgt()
{
  __prepared "__prepared_cmdmgt"
}

__queue_cmd()
{
  __debug $@
  
  typeset cmd=

  OPTIND=1
  while getoptex "c: cmd:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cmd'  ) cmd="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${cmd}" )" -eq "${YES}" ] && return "${FAIL}"

  __LOCAL_Q_COMMANDS+="${cmd}%@%"

  return "${PASS}"
}

__reset_cmd_stats()
{
  if [ -f "${__CMD_STORE_MAP_FILE}" ]
  then
    \rm -f "${__CMD_STORE_MAP_FILE}"
    \touch "${__CMD_STORE_MAP_FILE}"
  fi
  return "${PASS}"
}

__store_command()
{
  typeset last_cmd="$1"
  [ "$( is_empty --str "${last_cmd}" )" -eq "${YES}" ] && return "${PASS}"

  hadd_entry_via_file --filename "${__CMD_STORE_MAP_FILE}" --key 'last_cmd' --value "${last_cmd}"

  typeset current_cmd_id="$( __access_data --mapfile "${__CMD_STORE_MAP_FILE}" --key 'last_cmd_id' )"
  [ "$( is_empty --str "${current_cmd_id}" )" -eq "${YES}" ] && current_cmd_id=0

  hadd_entry_via_file --filename "${__CMD_STORE_MAP_FILE}" --key 'last_cmd_id' --value "${last_cmd_id}"
  return "${PASS}"
}

__store_command_rc()
{
  typeset last_cmd_rc="$1"
  [ "$( is_empty --str "${last_cmd}" )" -eq "${YES}" ] && last_cmd_rc="${PASS}"

  hadd_entry_via_file --filename "${__CMD_STORE_MAP_FILE}" --key 'last_cmd_rc' --value "${last_cmd_rc}"
  return "${PASS}"
}

__update_channel_list()
{
  typeset listid="$1"
  typeset data="$2"
  typeset is_unique=${3:-${NO}}

  [ -z "${listid}" ] && return "${PASS}"
  [ -z "${data}" ] && return "${PASS}"

  typeset cmdflags=
  [ "${is_unique}" -ne "${NO}" ] && cmdflags=' --unique'

  list_add --object "${listid}" --data "${data}" ${cmdflags}
  return $?
}

disable_cmd_recording()
{
  __ALLOW_CMD_RECORDING="${NO}"
  return "${PASS}"
}

enable_cmd_recording()
{
  __ALLOW_CMD_RECORDING="${YES}"
  return "${PASS}"
}

get_last_cmd()
{
  typeset last_cmd="$( __access_data --mapfile "${__CMD_STORE_MAP_FILE}" --key 'last_cmd' )"
  [ -n "${last_cmd}" ] && printf "%q\n" "${last_cmd}"
  return "${PASS}"
}

get_last_cmd_code()
{
  typeset last_cmd_rc="$( __access_data --mapfile "${__CMD_STORE_MAP_FILE}" --key 'last_cmd_rc' )"
  [ -n "${last_cmd_rc}" ] && printf "%d\n" "${last_cmd_rc}"
  return "${PASS}"
}

get_last_cmd_id()
{
  typeset last_cmd_id="$( __access_data --mapfile "${__CMD_STORE_MAP_FILE}" --key 'last_cmd_id' )"
  [ -n "${last_cmd_id}" ] && printf "%d\n" "${last_cmd_id}"
  return "${PASS}"
}

issue_cmd()
{
  __debug $@

  typeset RC="${PASS}"

  typeset cmd=
  typeset channels="${__CMD_RECORD_CHANNEL}"
  typeset output_file=
  typeset save_output="${NO}"
  typeset dryrun="${NO}"

  OPTIND=1
  while getoptex "${ALLOWED_CMD_INTERFACE_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    's'|'channel'       ) channels+=" ${OPTARG}";;
    'c'|'cmd'           ) cmd="${OPTARG}";;
    'f'|'output-file'   ) output_file="${OPTARG}";;
    'o'|'save-output'   ) save_output="${YES}";;
    'd'|'dryrun'        ) dryrun="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${cmd}" ] && return "${FAIL}"
 
  [ "$( is_empty --str "${channels}" )" -eq "${NO}" ] && __update_channel_list 'channel_list' "${channels}" "${YES}"

  typeset tee_channels=
  typeset ch=
  for ch in $( list_data --object 'channel_list' )
  do
    tee_channels+=" --channel ${ch}"
  done
  list_clear --object 'channel_list'

  #[ "${__ALLOW_CMD_RECORDING}" -eq "${YES}" ] && [ -n "${tee_channels}" ] && record_cmd --cmd "${cmd}" ${tee_channels}

  __store_command "${cmd}"

  typeset result=
  if [ "${dryrun}" -eq "${NO}" ]
  then
    eval "result=\"\$( ${cmd} 2>&1 )\""
    RC=$?
  else
    result='__DRYRUN__'
    RC="${PASS}"
  fi

  __store_command_rc "${RC}"

  typeset outputopts=
  if [ "${save_output}" -eq "${YES}" ]
  then
    result="$( printf "%s\n" "${result}" | \sed -e ":a;N;\$!ba;s/\\n/${__CMDMGT_NEWLINE_MARKER}/g" )"
    outputopts+=" --save-output"
    [ -n "${output_file}" ] && outputopts+=" --output-file ${output_file}"
 
    output_file="$( record_cmd_output --return-code "${RC}" ${outputopts} --result "${result}" )"
    [ -n "${output_file}" ] && printf "%s\n" "${output_file}"
  else
    printf "%s\n" "${result}"
  fi

  [ "${__ALLOW_CMD_RECORDING}" -eq "${YES}" ] && [ -n "${tee_channels}" ] && record_cmd --cmd "${cmd} || RC = ${RC}" ${tee_channels}

  return "${PASS}"
}

record_cmd()
{
  __debug $@

  typeset RC="${PASS}"
  typeset cmd=
  typeset channels="${__CMD_RECORD_CHANNEL}"
  typeset filename=

  OPTIND=1
  while getoptex "c: cmd: s: channel: f: filename:" "$@"
  do
    case "${OPTOPT}" in
   'c'|'cmd'      ) cmd="${OPTARG}";;
   's'|'channel'  ) channels+=" ${OPTARG}";;
   'f'|'filename' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${cmd}" ] && return "${FAIL}"
  if [ -n "${filename}" ]
  then
    typeset matched_channel="$( find_output_channel --file "${filename}" )"
    [ -n "${matched_channel}" ] && channels+=" ${matched_channel}"
  fi

  [ "$( is_empty --str "${channels}" )" -eq "${NO}" ] && __update_channel_list 'channel_list_rec' "${channels}" "${YES}"

  typeset tee_channels=
  typeset ch=
  for ch in $( list_data --object 'channel_list_rec' )
  do
    tee_channels+=" --channel ${ch}"
  done
  list_clear --object 'channel_list_rec'

  ###
  ### Record command to proper channel
  ###
  if [ -n "${tee_channels}" ]
  then
    append_output_tee --data "${cmd}" ${tee_channels}
    RC=$?
    return "${RC}"
  fi
  return "${PASS}"
}

record_cmd_output()
{
  __debug $@

  typeset RC="${PASS}"

  typeset channels=
  typeset return_code="${PASS}"
  typeset result=
  typeset output_file=
  typeset save_output="${NO}"

  OPTIND=1
  while getoptex "r: result: R: return-code: f: output-file: c: channel: o save-output" "$@"
  do
    case "${OPTOPT}" in
    'R'|'return-code'    ) return_code="${OPTARG}";;
    'r'|'result'         ) result="${OPTARG}";;
    'f'|'output-file'    ) output_file="${OPTARG}";;
    'c'|'output-channel' ) channels+=" ${OPTARG}";;
    'o'|'save-output'    ) save_output="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${save_output}" -eq "${NO}" ] && return "${PASS}"

  typeset finalch=
  typeset ch=
  for ch in ${channels}
  do
    typeset matchfile="$( find_output_file --channel "${ch}" )"
    RC=$?
    [ -n "${matchfile}" ] && [ "${RC}" -eq "${PASS}" ] && finalch+=" ${ch}"
  done

  ###
  ### Record the output from the command run
  ###
  if [ "${save_output}" -eq "${YES}" ]
  then
    [ "$( is_empty --str "${output_file}" )" -eq "${YES}" ] && output_file="$( make_output_file )"
    if [ -n "${output_file}" ]
    then
      typeset ofchan="$( find_output_channel --file "${output_file}" )"
      [ -n "${ofchan}" ] && finalch+=" ${ofchan}"

      if [ -n "${result}" ]
      then

        [ "$( is_empty --str "${finalch}" )" -eq "${NO}" ] && __update_channel_list 'channel_list_rec' "${finalch}" "${YES}"

        typeset tee_channels=
        typeset ch=
        for ch in $( list_data --object 'channel_list_rec' )
        do
  	      tee_channels+=" --channel ${ch}"
        done
        list_clear --object 'channel_list_rec'

        append_output_tee ${tee_channels} --data "RC = ${return_code}" --raw
        append_output_tee ${tee_channels} --data "${result}" --raw --substitution "${__CMDMGT_NEWLINE_MARKER}"
      fi
      printf "%s\n" "${output_file}"
    fi
  fi

  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null

  . "${SLCF_SHELL_TOP}/lib/data_structures.sh"
fi

__initialize_cmdmgt
__prepared_cmdmgt
