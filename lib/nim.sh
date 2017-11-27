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
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- UIM Setup
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_nimsoft_executable_version
#    __get_nimsoft_password
#    __get_packaging_password
#    __reset_all_passwords
#    __reset_nimsoft_password
#    __reset_packaging_password
#    __set_nimsoft_password
#    __set_packaging_password
#    compare_version
#    determine_robot_ids
#    get_nimsoft_directory
#    get_nimsoft_hub_adapter_version
#    get_nimsoft_hub_version
#    get_nimsoft_robot_version
#    get_nimsoft_spooler_version
#    get_nimsoft_probe_executable
#    get_nimsoft_user
#    get_nimsoft_user_pswd
#    get_pu_addon_options
#    is_hub
#    is_robot
#    run_pu_command
#    set_nimsoft_user
#    set_nimsoft_user_pswd
#
###############################################################################

###
### This uses the internal communication model inherit to UIM controllers
###   to allow for communications regardless of OS type.  If the need
###   is necessary to communicate outside of UIM, then a different library
###   should be employed.
###

if [ -z "${DEFAULT_NIM_ADMIN}" ]
then
  DEFAULT_NIM_ADMIN='administrator'

  DEFAULT_NIM_ADMIN_PWD='ENC{{{RU5De3t7ZEROemRHazV9fX0=}}}'
  DEFAULT_NIM_PKG_PWD='ENC{{{RU5De3t7YUdWcExtOW5MbWh2Y0hBPX19fQ==}}}'

  DEFAULT_NIM_UNIX_HOME='/opt/nimsoft'
  DEFAULT_NIM_WINDOWS_HOME='/cygdrive/c/Program Files (x86)\Nimsoft'

  NIM_ADMIN_PWD="${DEFAULT_NIM_ADMIN_PWD}"
  NIM_PKG_PWD="${DEFAULT_NIM_PKG_PWD}"

  EQUALS=1
  GREATERTHAN=2
  LESSTHAN=0
  NOT_EQUALS=3
fi

__get_nimsoft_executable_version()
{
  __debug $@

  typeset exepath=
  typeset exename=
  typeset version_option=

  OPTIND=1
  while getoptex "p: exepath: e: exename: version-flag" "$@"
  do
    case "${OPTOPT}" in
    'p'|'exepath'       ) exepath="${OPTARG}";;
    'e'|'exename'       ) exename="${OPTARG}";;
        'version-flag'  ) version_option="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${exename}" ) -eq "${YES}" ] && return "${FAIL}"
  if [ $( is_empty --str "${exepath}" ) -eq "${YES}" ]
  then
    execmd="./${exename}"
  else
    execmd="${exepath}/${exename}"
  fi

  [ ! -x "${execmd}" ] && return "${FAIL}"

  typeset fullversion=$( issue_cmd --cmd "${execmd} ${version_option}" )
  
  ###
  ### Need to break this information down using a regex... TODO
  ###
  typeset version="$( printf "%s\n" "${fullversion}" | \sed -e 's# #\1#' )"
  printf "%s\n" "${version}"
  return "${PASS}"
}

__get_nimsoft_password()
{
  __debug $@

  printf "%s\n" "$( decode_password "$( decode_password "${NIM_ADMIN_PWD}" )" )"
  return "${PASS}"
}

__get_packaging_password()
{
  __debug $@

  printf "%s\n" "$( decode_password "$( decode_password "${NIM_PKG_PWD}" )" )"
  return "${PASS}"
}

__initialize_nim()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"
  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"
  __load __initialize_networkmgr "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  __load __initialize_nim_pu "${SLCF_SHELL_TOP}/lib/nim_pu.sh"
  __load __initialize_passwordmgt "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
  __load __initialize_cmdmgt "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  __load __initialize_sshmgt "${SLCF_SHELL_TOP}/lib/sshmgt.sh"
 
  __initialize "__initialize_nim"
}

__prepared_nim()
{
  __prepared "__prepared_nim"
}

__reset_all_passwords()
{
  __reset_nimsoft_password
  __reset_packaging_password
  return "${PASS}"
}

__reset_nimsoft_password()
{
  __debug $@

  NIM_ADMIN_PWD="${DEFAULT_NIM_ADMIN_PWD}"
  return "${PASS}"
}

__reset_packaging_password()
{
  __debug $@

  NIM_PKG_PWD="${DEFAULT_NIM_PKG_PWD}"
  return "${PASS}"
}

__set_nimsoft_password()
{
  __debug $@

  [ -z "$1" ] && return "${FAIL}"
  NIM_ADMIN_PWD="$( encode_password "$( encode_password "$1" )" )"
  return "${PASS}"
}

__set_packaging_password()
{
  __debug $@

  [ -z "$1" ] && return "${FAIL}"
  NIM_PKG_PWD="$( encode_password "$( encode_password "$1" )" )"
  return "${PASS}"
}

compare_version()
{
  __debug $@

  typeset v1="$1"
  typeset v2="$2"

  [ -z "${v1}" ] || [ -z "${v2}" ] && return "${NOT_EQUALS}"
  while [[ ${v1} != '0' || ${v2} != '0' ]]
  do
    ###
    ### Need to handle non-numeric characters  (use is_numeric call and possibly sort type return...)
    ###
    typeset v1_nc="${v1%%.*}"
    typeset v2_nc="${v2%%.*}"

    (( ${v1%%.*} > ${v2%%.*} )) && return "${GREATERTHAN}"
    (( ${v1%%.*} < ${v2%%.*} )) && return "${LESSTHAN}"
    [[ ${v1} =~ '.' ]] && v1="${v1#*.}" || v1=0
    [[ ${v2} =~ '.' ]] && v1="${v2#*.}" || v2=0
  done
  return "${EQUAL}"
}

determine_robot_ids()
{
  __debug $@

  typeset entity
  for entity in "$@"
  do
    __debug "Handling entity : ${entity}"
  done
}

get_nimsoft_directory()
{
  __debug $@

  typeset localip=$( get_machine_ip )
  typeset ip="${localip}"
  typeset ip_user=root

  OPTIND=1
  while getoptex "i: ip: p: path: u: user:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ip'    ) ip="${OPTARG}";;
    'p'|'path'  ) path="${OPTARG}";;
    'u'|'user'  ) ip_user="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_ip_addr "${ip}" ) -eq "${NO}" ] && return "${FAIL}"

  typeset checkip="${ip}"
  [ "${ip}" == "${localip}" ] && checkip='local'
  
  typeset nimhome="$( hget --map 'UIM' --key "${ip}" )"

  if [ -z "${nimhome}" ]
  then
    typeset find_toplevel='/'

    [ $( is_empty --str "${path}" ) -eq "${NO}" ] && find_toplevel="${path}"

    typeset find_options="\"${find_toplevel}\" -type f -printf \"%T@ :%f %p\n\" -name \"robot.cfg\" | \sort -nr | \cut -f 2- -d ':' | \head -n 1"
    typeset find_file_output=$( make_temp_file )
    typeset findcmd=
    typeset output=

    if [ "${ip}" == "${localip}" ]
    then
      if [ -z "${NIMHOME}" ]
      then
        make_executable --exe 'find'
        typeset RC=$?
        if [ "${RC}" -eq "${PASS}" ]
        then
          findcmd="${find_exe}"
        else
          [ -f "${find_file_output}" ] && \rm -f "${find_file_output}"
          return "${FAIL}"
        fi
        issue_cmd --cmd "${findcmd} ${find_options}" > "${find_file_output}"
      else
        nimhome="${NIMHOME}"
        hadd --map 'UIM' --key 'local' --value "${nimhome}"
        printf "%s\n" "${nimhome}"
        return "${PASS}"
      fi
    else
      ###
      ### Need to determine of the type of machine is windows/cygwin
      ###
      typeset result="$( issue_ssh_cmd --cmd "ssh ${ip_user}@${ip} 'uname -a'" )"
      typeset REMOTE_OSVARIETY="$( determine_machine_os --data "${result}" --cache )"
      
      determine_cmd="${NO}"
      case "${REMOTE_OSVARIETY}" in
      'linux'|'solaris'|'aix'|'hpux'  ) determine_cmd="${YES}";;
      esac
      
      findcmd='find'
      if [ "${determine_cmd}" -eq "${YES}" ]
      then
        result="$( issue_ssh_cmd --cmd "ssh ${ip_user}@${ip} 'which find'" )"
        [ -n "${result}" ] && findcmd="${result}"
      fi
      issue_ssh_cmd --cmd "ssh ${ip_user}@${ip} \"${findcmd} ${find_options} 2>/dev/null\"" --output-file "${find_file_output}" --save-output
    fi

    nimhome=$( \dirname "$( \head -n 1 '${find_file_output}' )" )
    if [ $( is_empty --str "${nimhome}" ) -eq "${YES}" ]
    then
      case "${REMOTE_OSVARIETY}" in
      'linux'|'solaris'|'aix'|'hpux' ) nimhome="${DEFAULT_NIM_UNIX_HOME}";;
      'cygwin'|'windows'             ) nimhome="${DEFAULT_NIM_WINDOWS_HOME}";;
      esac
    fi
    hadd --map 'UIM' --key "${ip}" --value "${nimhome}"
  fi

  printf "%s\n" "${nimhome}"
  return "${PASS}"
}

get_nimsoft_hdb_version()
{
  __debug $@

  get_nimsoft_probe_version --probe-id 'hdb' --rel-probe-path 'probes/service'
  return $?
}

get_nimsoft_hub_adapter_version()
{
  __debug $@

  get_nimsoft_probe_version --probe-id 'hub_adapter' --rel-probe-path 'hub/hub_adapter'
  return $?
}

get_nimsoft_hub_version()
{
  __debug $@

  get_nimsoft_probe_version --probe-id 'hub' --rel-probe-path 'hub'
  return $?
}

get_nimsoft_probe_version()
{
  __debug $@

  typeset probe_id=
  typeset probe_path=

  OPTIND=1
  while getoptex "p: probe: rel-probe-path" "$@"
  do
    case "${OPTOPT}" in
    'p'|'probe'       ) probe_id="${OPTARG}";;
    'rel-probe-path'  ) probe_path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${probe_id}" ) -eq "${YES}" ]
  then
    printf "%s\n" '-1.0'
    return "${FAIL}"
  fi

  typeset probe_coordinate=

  if [ -n "${probe_path}" ]
  then
    probe_coordinate="${probe_path}/${probe_id}"
  else
    probe_coordinate="${probe_id}"
  fi

  typeset nimhome=$( get_nimsoft_directory )
  if [ -d "${nimhome}" ] && [ -d "${nimhome}/${probe_coordinate}" ]
  then
    __get_nimsoft_executable_version "${nimhome}/${probe_coordinate}" $( \basename "${probe_coordinate}" ) --version-flag '-V'
    return "${PASS}"
  fi
  return "${FAIL}"
}

get_nimsoft_robot_version()
{
  __debug $@

  get_nimsoft_probe_version --probe-id 'controller' --rel-probe-path 'robot'
  return $?
}

get_nimsoft_spooler_version()
{
  __debug $@

  get_nimsoft_probe_version --probe-id 'spooler' --rel-probe-path 'robot'
  return $?
}

get_nimsoft_probe_executable()
{
  __debug $@

  typeset probe=

  OPTIND=1
  while getoptex "p: probe:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'probe' ) probe="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${probe}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset nimhome=$( get_nimsoft_directory )
  typeset special_probes='hub/hub hub/hub_adapter/hub_adapter robot/controller robot/spooler'

  typeset p
  for p in ${special_probes}
  do
    typeset spname=$( \basename "${p}" )
    if [ "${probe}" == "${spname}" ]
    then
      printf "%s\n" "${nimhome}/${p}"
      return "${PASS}"
    fi
  done

  make_executable --exe 'find'
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset probe_loc="$( issue_cmd --cmd "${find_exe} '${nimhome}' -type d -name '${probe}' 2>&1" )"
  [ $( is_empty --str "${probe_loc}" ) -eq "${YES}" ] && return "${FAIL}"

  printf "%s" "${probe_loc}/${probe}"
  return "${PASS}"
}

get_nimsoft_user()
{
  __debug $@

  typeset nimuser=$( hget --map UIM --key 'nimuser' )

  if [ $( is_empty --str "${nimuser}" ) -eq "${NO}" ]
  then
    printf "%s" "${nimuser}"
  else
    printf "%s" "${DEFAULT_NIM_ADMIN}"
  fi
  return "${PASS}"
}

is_hub()
{
  __debug $@

  typeset ip=

  OPTIND=1
  while getoptex "i: ip:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ip'  ) ip="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${ip}" ) -eq "${YES}" ] && ip=$( get_machine_ip )

  typeset nimhome=$( get_nimsoft_directory --ip "${ip}" )
  if [ $( is_empty --str "${nimhome}" ) -eq "${YES}" ]
  then
    print_no
    return "${PASS}"
  fi

  if [ -x "${nimhome}/hub/hub" ]
  then
    print_yes
  else
    print_no
  fi

  return "${PASS}"
}

set_nimsoft_user()
{
  __debug $@
  typeset nimuser="$1"

  [ $( is_empty --str "${nimuser}" ) -eq "${YES}" ] && return "${FAIL}"
  hput --map UIM --key 'nimuser' --value "${nimuser}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/filemgt.sh"
  . "${SLCF_SHELL_TOP}/lib/numerics.sh"
  . "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/sshmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"
  . "${SLCF_SHELL_TOP}/lib/nim_pu.sh"
fi

__initialize_nim
__prepared_nim

