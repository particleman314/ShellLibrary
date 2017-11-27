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
# Software Package : Shell Automated Testing -- SSH Remote Functionality
# Application      : Product Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __clear_queued_ssh_cmds
#    __execute_remote_queue_cmds
#    __install_executable
#    __queue_ssh_cmd
#    __run_passwordless_access_check
#    check_for_passwordless_connection
#    has_sshkey
#    issue_ssh_cmd
#    make_passwordless_connection
#    make_sshkey
#
###############################################################################

__clear_queued_ssh_cmds()
{
  __debug $@
  
  __REMOTE_Q_COMMANDS=
  return "${PASS}"
}

__execute_remote_queue_cmds()
{
  __debug $@
  
  typeset filename=
  typeset error_on_failure="${YES}"

  OPTIND=1
  while getoptex "f: filename: continue-on-fail" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'          ) filename="${OPTARG}";;
        'continue-on-fail'  ) error_on_failure="${NO}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${filename}" ) -eq "${YES}" ]
  then
    typeset sshchn="$( make_output_file --prefix 'SSH' )"
    filename=$( find_output_file --channel "${sshchn}" )
  fi

  [ -n "${__SSH_COMMANDS}" ] && printf "%s\n" "${__SSH_COMMANDS}" | \awk 'BEGIN {FS="%@%"} {for(i=1;i<=NF;i++)print $i}' >> "${filename}"
  
  __clear_ssh_commands
  
  typeset line=
  typeset RC="${PASS}"
  while read -u 9 -r line
  do
    __issue_ssh_cmd "${line}"
    typeset __RC=$?
    if [ ${error_on_failure} -eq "${YES}" ]
    then
      [ ${__RC} -ne "${PASS}" ] && return "${FAIL}"
    else
      RC=$( increment "${RC}" $? )
    fi
    [ "${RC}" -gt ${MAX_RETURN_CODE} ] && RC=${MAX_RETURN_CODE}
  done
  
  printf "%s\n" "${outputfile}:${filename}"
  return "${RC}"
}

__initialize_sshmgt()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_execaching "${SLCF_SHELL_TOP}/lib/execaching.sh"
  __load __initialize_machinemgt "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  __load __initialize_networkmgt "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  __load __initialize_pkgmgt "${SLCF_SHELL_TOP}/lib/pkgmgt.sh"
  __load __initialize_cmdmgt "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  __load __initialize_cmd_interface "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"

  __REMOTE_Q_COMMANDS=
  __REMOTE_CMD_ISSUE_ID=0

  __REMOTE_CHANNEL='SSH'

  make_executable --exe 'ssh'
  make_executable --exe 'sshpass'
  make_executable --exe 'ssh-copy-id' --alias 'sshcopyid'

  __initialize '__initialize_sshmgt'
}

__install_executable()
{
  __debug $@
  
  typeset exename="$1"
  [ -z "$1" ] && return "${PASS}"
  
  typeset res_exe=
  make_executable --exe "${exename}"
  eval "res_exe=\${${exename}_exe}"

  if [ $( is_empty --str "${res_exe}" ) -eq "${YES}" ]
  then
    install_package "${exename}"  ### This requires the pkgmgt library
    typeset RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    make_executable --exe "${exename}"
    eval "res_exe=\${${exename}_exe}"
    [ $( is_empty --str "${res_exe}" ) -eq "${YES}" ] && return "${FAIL}"
  fi
  return "${PASS}"
}

__prepared_sshmgt()
{
  __prepared '__prepared_sshmgt'
}

__queue_ssh_cmd()
{
  __debug $@
  
  typeset cmd=
  typeset remote_user=
  typeset remote_ip=
  typeset raw="${NO}"

  OPTIND=1
  while getoptex "c: cmd: u: remote-user: i: remote-ip: raw" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cmd'          ) cmd="${OPTARG}";;
    'u'|'remote-user'  ) remote_user="${OPTARG}";;
    'i'|'remote-ip'    ) remote_ip="${OPTARG}";;
        'raw'          ) raw="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${cmd}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${remote_ip}" ) -eq "${YES}" ] && remote_ip="${__LOCAL_MACHINE_IP}"

  if [ "${remote_ip}" != "${__LOCAL_MACHINE_IP}" ]
  then
    [ $( is_empty --str "${remote_user}" ) -eq "${YES}" ] && return "${FAIL}"
  fi

  if [ "${remote_ip}" == "${__LOCAL_MACHINE_IP}" ]
  then
    __queue_cmd --cmd "$( escapify ${cmd} )"
  else
    if [ "${raw}" -eq "${NO}" ]
    then
      __REMOTE_Q_COMMANDS+="${ssh_exe} ${remote_user}@${remote_ip} '${cmd}'%@%"
    else
      __REMOTE_Q_COMMANDS+="${cmd}%@%"
    fi
  fi

  return "${PASS}"
}

__run_passwordless_access_check()
{
  __debug $@

  typeset RC="${PASS}"

  typeset remote_user=
  typeset remote_host=
  typeset remote_ip=

  OPTIND=1
  while getoptex "u: user: h: remote-host: i: remote-ip:" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user'        ) remote_user="${OPTARG}";;
    'h'|'remote-host' ) remote_host="${OPTARG}";;
    'i'|'remote-ip'   ) remote_ip="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${user}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  if [ $( is_empty --str "${remote_ip}" ) -eq "${YES}" ]
  then
    [ $( is_empty --str "${host}" ) -eq "${YES}" ] && return "${FAIL}"
    remote_name="${remote_host}"
  else
    remote_name="${remote_ip}"
  fi

  typeset sshopts=
  sshopts+=' -o ConnectTimeout=5'
  sshopts+=' -o StrictHostKeyChecking=no'
  sshopts+=' -o BatchMode=yes'

  typeset output="$( __issue_ssh_cmd "${ssh_exe} ${sshopts} ${remote_user}@${remote_name} 'ls -l'" )"
  RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
  else
    print_yes
  fi

  return "${PASS}"
}

check_for_passwordless_connection()
{
  __debug $@

  typeset remote_ip=
  typeset remote_user=

  OPTIND=1
  while getoptex "i: remote-ip: r: remote-user:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'remote-ip'    ) remote_ip="${OPTARG}";;
    'r'|'remote-user'  ) remote_user="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${remote_ip}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  if [ $( is_empty --str "${remote_user}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  # Try to login to the machine in question ( or see if its connection is cached )
  # If success without entering password, then return PASS otherwise FAIL

  if [ $( is_host_alive "${remote_ip}" ) -eq "${NO}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset prior_comm=$( has_prior_connection --ip "${remote_ip}" --remote-user "${remote_user}" )
  if [ "${prior_comm}" -eq "${NO}" ]
  then
    typeset answer=$( __run_passwordless_access_check --user "${remote_user}" --host "${remote_ip}" )
    typeset RC=$?
  
    if [ "${RC}" -eq "${PASS}" ]
    then
      if [ "${answer}" -eq "${YES}" ]
      then
        hadd_item --map 'PASSWORDLESS_CONNECTIONS' --key "C_$( translate_ip_format "${remote_ip}" forward )_${remote_user}" --value "${YES}"
        print_yes
      else
        print_no
      fi
    fi
    return "${RC}"
  else
    print_yes
    return "${PASS}"
  fi
}

has_prior_connection()
{
  __debug $@

  typeset remote_ip=
  typeset remote_user=

  OPTIND=1
  while getoptex "i: ip: r: remote-user:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ip'           ) remote_ip="${OPTARG}";;
    'r'|'remote-user'  ) remote_user="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${remote_ip}" ) -eq "${YES}" ] || [ $( is_empty --str "${remote_user}" ) -eq "${YES}" ]
  then
    print_no
    return "${PASS}"
  fi
    
  typeset prior_comm=$( hget --map 'PASSWORDLESS_CONNECTIONS' --key "C_$( translate_ip_format "${remote_ip}" forward )_${remote_user}" )
  if [ $( is_empty --str "${prior_comm}" ) -eq "${YES}" ]
  then
    print_no
  else
    print_yes
  fi
  return "${PASS}"
}

has_sshkey()
{
  __debug $@

  typeset keytype='rsa'
  typeset userid=$( get_user_id )
  typeset userid_home=$( get_user_id_home )

  OPTIND=1
  while getoptex "u: user: h: home-dir: keytype:" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user'       ) userid="${OPTARG}";;
    'p'|'home-dir'   ) userid_home="${OPTARG}";;
        'keytype'    ) keytype="$( to_lower "${OPTARG}" )";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${userid_home}" ) -eq "${YES}" ] || [ ! -d "${userid_home}/.ssh" ]
  then
    print_no
    return "${PASS}"
  fi

  typeset localip=$( get_machine_ip | translate_ip_format )

  if [ $( is_empty --str "${keytype}" ) -eq "${YES}" ]
  then
    typeset idfiles
    idfiles=$( \ls -1 "${userid_home}"/id_* )
    [ $( is_empty --str "${idfiles}" ) -eq "${YES}" ] && print_no
  else
    [ ! -f "${userid_home}/.ssh/id_${keytype}" ] && print_no
  fi
  return "${PASS}"
}

issue_ssh_cmd()
{
  typeset RC="${PASS}"

  typeset cmd=
  typeset channels="${__REMOTE_CHANNEL}"
  typeset output_file=
  typeset save_output="${NO}"

  OPTIND=1
  while getoptex "${ALLOWED_CMD_INTERFACE_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    's'|'channel'       ) channels+=" ${OPTARG}";;
    'c'|'cmd'           ) cmd="${OPTARG}";;
    'f'|'output-file'   ) output_file="${OPTARG}";;
    'o'|'save-output'   ) save_output="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${cmd}" ) -eq "${YES}" ] && return "${FAIL}"

  __REMOTE_CMD_ISSUE_ID=$( increment "${__REMOTE_CMD_ISSUE_ID}" )

  __update_channel_list 'channel_list' "${channels}" "${YES}"

  typeset tee_channels=
  typeset ch=
  for ch in $( list_data --object 'channel_list' )
  do
    tee_channels+=" --channel ${ch}"
  done
  list_clear --object 'channel_list'

  ###
  ### Record command to SSH channel
  ###
  append_output --data "CMD(${__REMOTE_CMD_ISSUE_ID}) : ${cmd}" ${tee_channels}

  typeset result=
  eval "result=\$( ${cmd} ) 2>&1"
  RC=$?
  if [ $( is_empty --str "${result}" ) -eq "${NO}" ]
  then
    typeset outputopts=
    [ -n "${output_file}" ] && outputopts=" --output-file '${output_file}'"

    output_file="$( record_cmd_output --return-code "${RC}" --result "${result}" --save-output "${save_output}" --channel "${__REMOTE_CHANNEL}" --raw ${outputopts} )"

    if [ "${save_output}" -eq "${YES}" ]
    then
      [ -n "${output_file}" ] && printf "%s\n" "${output_file}"
    else
      printf "%s\n" "${result}"
    fi
  fi
  return "${RC}"
}

make_passwordless_connection()
{
  __debug $@

  typeset RC="${PASS}"

  typeset remote_ip=
  typeset remote_user=
  typeset remote_userpwd=
  typeset keytype='rsa'

  OPTIND=1
  while getoptex "i: remote-ip: u: remote-user: p: remote-pass: keytype:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'remote-ip'    ) remote_ip="${OPTARG}";;
    'u'|'remote-user'  ) remote_user="${OPTARG}";;
    'p'|'remote-pass'  ) remote_userpwd="${OPTARG}";;
        'keytype'      ) keytype="$( to_lower "${OPTARG}" )";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset answer=$( check_for_passwordless_connection --remote-ip "${remote_ip}" --remote-user "${remote_user}" )
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  [ ${answer} -eq "${YES}" ] && return "${PASS}"

  typeset userid=$( get_user_id )

  typeset result="$( __issue_ssh_cmd "${sshpass} -p '${remote_pass}' ${ssh_exe} ${remote_user}@${remote_ip} \"sed '/${userid}/d' .ssh/authorized_keys > .ssh/authorized_keys.1; mv -f .ssh/authorized_keys.1 .ssh/authorized_keys\"" )"
  typeset idfile="/root/.ssh/id_${keytype}"

  [ "$( get_user_id )" != 'root' ] && idfile="$( get_user_id_home )/.ssh/id_${keytype}"

  if [ ! -f "${idfile}" ]
  then
    make_sshkey --type "${keytype}" --bits 4096
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  result="$( __issue_ssh_cmd "${sshpass_exe} -p '${remote_pass}' ${sshcopyid_exe} -i \"${idfile}\" ${remote_user}@${remote_ip} > /dev/null 2>&1" )"
  RC=$?
  return "${RC}"
}

make_sshkey()
{
  __debug $@

  typeset RC="${PASS}"
  typeset keytype='rsa'
  typeset keybits='2048'

  typeset known_keytypes='rsa1 rsa dsa ecdsa'

  OPTIND=1
  while getoptex "t: type: b: bits:" "$@"
  do
    case "${OPTOPT}" in
    't'|'type'  ) keytype=$( to_lower "${OPTARG}" );;
    'b'|'bits'  ) keybits="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  RC="$( printf "%s\n" ${known_keytypes} | \grep "^${keytype}" )"
  typeset matched_keytype=$( __translate_rc "${RC}" )
  [ "${matched_keytype}" -eq "${NO}" ] && return "${FAIL}"

  # FIPS 186-2 compliance for DSA key bit size is 1024 only
  [ "${keytype}" == 'dsa' ] && keybits=1024
  
  typeset idfile="/root/.ssh/id_${keytype}"

  [ "$( get_user_id )" != 'root' ] && idfile="$( get_user_id_home )/.ssh/id_${keytype}"

  issue_cmd --cmd "${sshkeygen_exe} -q -N '' -t '${keytype}' -b ${keybits} -f \"${idfile}\" 1>/dev/null"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset localip=$( get_machine_ip | translate_ip_format )
  
  hput --map "secured_connection_${localip}" --key 'type' --value "${keytype}"
  hput --map "secured_connection_${localip}" --key 'bitsize' --value "${keybits}"

  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/execaching.sh"
  . "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  . "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/pkgmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  . "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"
fi

__initialize_sshmgt
__prepared_sshmgt
