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
## @Software Package : Shell Automated Testing -- Basic Machine Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.06
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __add_support_binaries
#    __ensure_local_machine_identified
#    __get_linux_variety
#    __get_linux_version
#    __output_match
#    __record
#    decode_remote_machinetype
#    get_temp_dir
#    is_mac_machine
#    is_posix_machine
#    is_windows_machine
#    local_machinespecs
#    remove_trailing_slash
#    validate_platform
#
###############################################################################

# shellcheck disable=SC1117,SC2039,SC2120,SC2068,SC2119,SC2016

__add_support_binaries()
{
  ###
  ### Only need to add if not present...
  ###
  typeset components="$( printf "%s\n" "${PATH}" | \sed -e "s#${SEPARATOR}# #g" )"
  typeset found_in_path="${NO}"
  typeset sb_path="$( ${__REALPATH} ${__REALPATH_OPTS} "${SLCF_SHELL_TOP}/resources/$( __get_resource_subpath )" )"
  typeset c=
  for c in ${components}
  do
    typeset resolved=$( ${__REALPATH} ${__REALPATH_OPTS} "${c}" )
    if [ "${resolved}" == "${sb_path}" ]
    then
      found_in_path="${YES}"
      break
    fi
  done
  
  [ "${found_in_path}" -eq "${NO}" ] && eval "PATH=\"${SLCF_SHELL_TOP}/resources/$( __get_resource_subpath ):${PATH}\""
  return "${PASS}"
}

__ensure_local_machine_identified()
{
  __debug $@

  if [ -z "${OSVARIETY}" ]
  then
    __debug "Determining type of machine..."
    local_machinespecs
    typeset RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi
  return "${PASS}"
}

__get_linux_variety()
{
  __debug $@

  typeset linux_distro='UNKNOWN'
  typeset RC=
  typeset distribution_files='/etc/redhat-release /etc/issue'
  typeset distribution_exe='lsb_release'
  
  typeset os_designation="${ostype}"
  [ -z "${os_designation}" ] && os_designation="${OSVARIETY}"
  if [ -z "${os_designation}" ]
  then
    print_plain --message "${linux_distro}"
    return "${FAIL}"
  fi

  os_designation="$( printf "%s\n" "${os_designation}" | \tr '[:upper:]' '[:lower:]' )"

  \which "${distribution_exe}" >/dev/null 2>&1
  if [ $? -eq "${PASS}" ]
  then
    typeset tmpdir="$( get_temp_dir )"
    ${distribution_exe} -d > "${tmpdir}/.linux_specific_type" 2>&1
    distribution_files+=" ${tmpdir}/.linux_specific_type"
  fi
  
  if [ "x${os_designation}" == "xlinux" ]
  then
    typeset df=
    for df in ${distribution_files}
    do
      [ ! -f "${df}" ] && continue
      \grep -iq 'RED HAT' "${df}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        linux_distro=RedHat
        break
      fi
      
      \grep -iq 'SUSE' "${df}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        linux_distro=SuSE
        break
      fi
      
      \grep -iq 'UBUNTU' "${df}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        linux_distro=Ubuntu
        break
      fi
      
      \grep -iq 'DEBIAN' "${df}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        linux_distro=Debian
        break
      fi
      
      \grep -iq 'CENTOS' "${df}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        linux_distro=CentOS
        break
      fi
    done
  fi
      
  print_plain --message "${linux_distro}"
  return "${PASS}"
}

__get_linux_version()
{
  __debug $@

  typeset linux_version='-1.0'
  typeset RC=
  typeset distribution_files='/etc/redhat-release /etc/issue'
  typeset distribution_exe='lsb_release'
  
  \which "${distribution_exe}" >/dev/null 2>&1
  RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    typeset tmpdir="$( get_temp_dir  )"
    ${distribution_exe} -d > "${tmpdir}/.linux_specific_type" 2>&1
    distribution_files+=" ${tmpdir}/.linux_specific_type"
  fi
  
  typeset os_designation="${ostype}"
  [ -z "${os_designation}" ] && os_designation="${OSVARIETY}"

  if [ "x${os_designation}" == "xlinux" ]
  then
    typeset df
    for df in ${distribution_files}
    do
      typeset column=4
      if [ "${df}" != '/etc/redhat-release' ] && [ "${df}" == '/etc/issue' ]
      then
        column=4
      else
        column=2
      fi
      linux_version=$( \tr -s ' ' < "${df}" | \cut -f ${column} -d ':' | \sed -e 's#[[:blank:]]##' )
      [ -n "${linux_version}" ] && break
    done
  fi
  
  print_plain --message "${linux_version}"
  return "${PASS}"
}

__get_resource_subpath()
{
  case "${OSVARIETY}" in
  'linux'    ) printf "%s\n" 'Linux';;
  'solaris'  ) printf "%s\n" 'Unix/Solaris';;
  'aix'      ) printf "%s\n" 'Unix/AIX';;
  'hpux'     ) printf "%s\n" 'Unix/HPUX';;
  'windows'  ) printf "%s\n" 'Windows';;
  'darwin'   ) printf "%s\n" 'MacOS';;
  esac
  return "${PASS}"
}

__initialize_base_machinemgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )
  
  __load __initialize_hashmaps "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  
  __ensure_local_machine_identified
  __initialize "__initialize_base_machinemgt"
}

__output_match()
{
  typeset input="$1"
  typeset nwords="${3:-0}"

  typeset match=
  if [ "${nwords}" -gt 0 ]
  then
    match="$( printf "%s\n" "${2}" | \cut -f 1-${nwords} -d ' ' )"
    printf "%s\n" "${input}" | \grep -q "${match}"
    case $? in
      0 ) printf "%d\n" 1;;
      * ) printf "%d\n" 0;;
    esac
  elif [ "${nwords}" -eq '-1' ]
  then
    printf "%s\n" "${input}" | \grep -q "^$2"
    case $? in
      0 ) printf "%d\n" 1;;
      * ) printf "%d\n" 0;;
    esac
  else  
    match="$2"
    case "${match}" in
      "${input}"  ) printf "%d\n" 1;;  ## Match
      *           ) printf "%d\n" 0;;  ## Non-Match
    esac
  fi
  return 0
}

__prepared_base_machinemgt()
{
  __prepared "__prepared_base_machinemgt"
}

__record()
{
  __debug $@
  
  typeset data=
  typeset file=
  typeset method=
  typeset no_export=${NO}
 
  OPTIND=1
  while getoptex "d: data: f: file: m. method. n no-export" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'      ) data="${OPTARG}";;
    'f'|'file'      ) file="${OPTARG}";;
    'm'|'method'    ) method="${OPTARG}";;
    'n'|'no-export' ) no_export="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${data}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${method}" )" -eq "${YES}" ] && method='a'
  [ "$( is_empty --str "${file}" )" -eq "${YES}" ] && file='STDOUT'

  typeset key="$( printf "%s\n" "${data}" | \sed -e 's#=# #' | \cut -f 1 -d ' ' )"
  if [ "${file}" == 'STDOUT' ]
  then
    print_plain --message "${data}"
  else 
    if [ "${method}" == "a" ]
    then
      print_plain --message "${data}" >> "${file}"
    else
      print_plain --message "${data}" > "${file}"
    fi
    [ "${no_export}" -eq "${NO}" ] && print_plain --message "export ${key}" >> "${file}"
  fi
  return "${PASS}"
}

decode_remote_machinetype()
{
  __debug $@

  typeset machine_type="$( printf "%s\n" "$@" | \cut -f 1 -d ' ' | \cut -f 1 -d '-' | \tr [:upper:] [:lower:] )"

  if [ "x${machine_type}" == "xcygwin_nt" ]
  then
    printf "%s\n" 'windows'
  elif [ "x${machine_type}" == 'xaix' ]
  then
    printf "%s\n" 'aix'
  elif [ "x${machine_type}" == 'xsunos' ]
  then
    printf "%s\n" 'solaris'
  elif [ "x${machine_type}" == 'xhp-ux' ]
  then
    printf "%s\n" 'hp'
  else
    printf "%s\n" 'linux'
  fi

  return "${PASS}"
}

get_temp_dir()
{
  __debug $@
  
  typeset user_specified_tmp="$1"

  if [ -n "${user_specified_tmp}" ] && [ -d "${user_specified_tmp}" ]
  then
    print_plain --message "${user_specified_tmp}"
    return "${PASS}"
  fi

  typeset mapname='tempdirenvkeys'
  typeset mapkey='tempdirs'

  if [ "$( hexists --map "${mapname}" --key 'defined' )" -ne "${YES}" ]
  then
    typeset mapname='tempdirenvkeys'
    typeset mapkey='tempdirs'
    typeset envkeys='TEMPORARY_DIR TEMP TMP TEMPDIR TMPDIR'

    hadd_item --map "${mapname}" --key "${mapkey}" --value "${envkeys}"
    hadd_item --map "${mapname}" --key 'defined' --value "${YES}"
    hadd_item --map "${mapname}" --key 'reset' --value "${NO}"
  fi

  typeset possible_tmpdirs=$( hget --map "${mapname}" --key "${mapkey}" )

  if [ -n "${possible_tmpdirs}" ]
  then
    typeset tmploop=
    for tmploop in ${possible_tmpdirs}
    do
      typeset pt=
      eval "pt=\${${tmploop}}"

      if [ -d "${pt}" ]
      then
        print_plain --message "${pt}"
        if [ "$( hget --map "${mapname}" --key 'reset' )" -eq "${NO}" ]
        then
          hadd_item --map "${mapname}" --key 'reset' --value "${YES}"
          typeset rsttmp=
          for rsttmp in ${possible_tmpdirs}
          do
            eval "${rsttmp}=\"${pt}\""
          done
        fi
        return "${PASS}"
      fi
    done
  fi

  # Unable to find predefined ENV var relating to tmp directory
  typeset machine_type="${OSVARIETY}"
  [ "$( is_empty --str "${OSVARIETY}" )" -eq "${YES}" ] && machine_type="$( \uname -a | \cut -f 1 -d ' ' )"

  if [ "x${machine_type}" == "xCygwin" ] || [ "x${machine_type}" == "xwindows" ]
  then
    if [ -d "/c/temp/" ]
    then
      print_plain --message "c:/temp"
    else
      if [ -d "/c/tmp" ]
      then
        print_plain --message "c:/tmp"
      else
        \mkdir -p "/c/temp"
        \chmod -R 777 "/c/temp"
        [ $? -ne "${PASS}" ] && return "${FAIL}"
        print_plain --message "c:/temp"
      fi
    fi
  else
    print_plain --message '/tmp'
  fi
  return "${PASS}"
}

is_mac_machine()
{
  __debug $@
  
  if [ "x${OSVARIETY}" == 'xdarwin' ]
  then
    print_yes
  else
    print_no
  fi
  
  return "${PASS}"
}

is_posix_machine()
{
  __debug $@
  
  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    print_no
  else
    print_yes
  fi
  
  return "${PASS}"
}

is_windows_machine()
{
  __debug $@

  typeset ignore_cygwin="${NO}"
  
  OPTIND=1
  while getoptex "no-cygwin" "$@"
  do
    case "${OPTOPT}" in
    'no-cygwin' ) ignore_cygwin="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "x${OSVARIETY}" == "xwindows" ] 
  then
    if [ "${ignore_cygwin}" -eq "${YES}" ]
    then
      print_plain --message "${YES}"
    elif [ -z "${EMULATION}" ] || [ "${EMULATION}" -ne 'cygwin' ]
    then
      print_plain --message "${YES}"
    else
      print_plain --message "${NO}"
    fi
  else
    print_plain --message "${NO}"
  fi
  return "${PASS}"
}

local_machinespecs()
{
  __debug $@

  typeset specfile="$( get_temp_dir )/.machinespecifications.sh"

  if [ -z "${OSBITSIZE}" ]
  then
    __record --data "#!${SHELL}" --file "${specfile}" --no-export --method w

    typeset machine_type="$( \uname -a | \cut -f 1 -d ' ' )"
    typeset machine_size="$( \uname -m )"

    if [ "x${machine_type}" == "xCygwin" ]
    then
      __record --data 'OSVARIETY=windows' --file "${specfile}"
      __record --data 'EMULATION=cygwin' --file "${specfile}"
  
      typeset cygpath_exe=
      typeset cmd="cygpath_exe=\$( \\which cygpath )"
      eval "${cmd}"

      if [ "$( is_empty --str "${cygpath_exe}" )" -eq "${YES}" ]
      then
        printf "\n%s\n" "For windows, CYGWIN must be installed for use!!"
	    return $?
      fi

      __record --data "SEPARATOR=\";\"" --file "${specfile}"
      __record --data "PATH_SEP=\"/\"" --file "${specfile}"

      if [ "$( is_empty "${ProgramW6432}" )" -eq "${NO}" ]
	    then
	      __record --data "OSBITSIZE=64" --file "${specfile}"
	    else
	      __record --data "OSBITSIZE=32" --file "${specfile}"
	    fi
    else
      if [ "x${machine_type}" == 'xAIX' ]
      then
        __record --data "OSVARIETY=aix" --file "${specfile}"
        __record --data "PATH_SEP=\"/\"" --file "${specfile}"
        __record --data "OSBITSIZE=64" --file "${specfile}"
      elif [ "x${machine_type}" == 'xSunOS' ]
      then
        __record --data "OSVARIETY=solaris" --file "${specfile}"
        __record --data "PATH_SEP=\"/\"" --file "${specfile}"
        __record --data "OSBITSIZE=64" --file "${specfile}"
      elif [ "x${machine_type}" == 'xHP-UX' ]
      then
        __record --data "OSVARIETY=hp" --file "${specfile}"
        __record --data "PATH_SEP=\"/\"" --file "${specfile}"
        __record --data "OSBITSIZE=64" --file "${specfile}"
      elif [ "x${machine_type}" == 'xDarwin' ]
      then
        __record --data "OSVARIETY=darwin" --file "${specfile}"
        __record --data "PATH_SEP=\"/\"" --file "${specfile}"
        __record --data "OSBITSIZE=64" --file "${specfile}"
      else
        __record --data "OSVARIETY=linux" --file "${specfile}"
        __record --data "PATH_SEP=\"/\"" --file "${specfile}"
        if [ "x${machine_size}" == "xx86_64" ]
        then
	        __record --data "OSBITSIZE=64" --file "${specfile}"
        else
	        __record --data "OSBITSIZE=32" --file "${specfile}"
        fi
      fi
      __record --data "SEPARATOR=\":\"" --file "${specfile}"
    fi 
  fi
  
  typeset tmpdir="$( get_temp_dir )"
  __record --data "TEMPORARY_DIR=${tmpdir}" --file "${specfile}"

  # shellcheck source=/dev/null

  . "${specfile}"
  [ -f "${specfile}" ] && \rm -f "${specfile}"
  return $?
}

remove_trailing_slash()
{
  __debug $@
  
  typeset str=

  OPTIND=1
  while getoptex "s. str." "$@"
  do
    case "${OPTOPT}" in
    's'|'str' ) str="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  str=$( trim "${str}" )
  [ "$( is_empty --str "${str}" )" -eq "${YES}" ] && return "${PASS}"

  typeset lastchar=${str#"${str%?}"}
  [ "x${lastchar}" == "x/" ] && str=${str%?}
  [ "x${lastchar}" == "x\\" ] && str=${str%??}
  
  [ "$( is_empty --str "${str}" )" -eq "${YES}" ] && return "${PASS}"
  
  print_plain --message "${str}"
  return "${PASS}"
}

validate_platform()
{
  LINUX_DISTRO=

  typeset MACHINETYPE_IDENTIFIER_FILES="$( \find /etc -maxdepth 1 -type f -name "*release" | \tr '\n' ' ' ) /etc/issue"

  typeset mif=
  for mif in ${MACHINETYPE_IDENTIFIER_FILES}
  do
    if [ -f "${mif}" ]
    then
      num_lines=$( \cat "${mif}" | \sed '/^$/d' | \wc -l )
      \grep -qi 'PRETTY_NAME' "${mif}"
      typeset specialty_line=$?
      [ "${specialty_line}" -eq 1 ] && [ "${num_lines}" -gt 2 ] && continue

      if [ "${specialty_line}" -eq 0 ]
      then
        POSSIBLE_LINUX_DISTRO="$( \cat "${mif}" | \grep -i 'PRETTY_NAME' | \sed -e 's#\\\w##g' | \sed -e 's#PRETTY_NAME=##i' )"
      else
        [ "${num_lines}" -gt 2 ] && continue
        POSSIBLE_LINUX_DISTRO="$( \cat "${mif}" | \sed -e 's#\\\w##g' )"
      fi

      POSSIBLE_LINUX_DISTRO="$( printf "%s\n" "${POSSIBLE_LINUX_DISTRO}" | \tr -d '\n' | \tr -d '"' | \sed -e 's#Kernel.*$##' )"

      if [ -z "${LINUX_DISTRO}" ]
      then
        LINUX_DISTRO="${POSSIBLE_LINUX_DISTRO}"
      else
        [ "$( output_match "${POSSIBLE_LINUX_DISTRO}" "${LINUX_DISTRO}" -1 )" -eq 1 ] && LINUX_DISTRO="${POSSIBLE_LINUX_DISTRO}"
      fi
    fi
  done

  if [ -n "${LINUX_DISTRO}" ]
  then
    LINUX_PLATFORM="$( printf "%s\n" "${LINUX_DISTRO}" | \cut -f 1 -d ' ' )"
    LINUX_VERSION="$( printf "%s\n" "${LINUX_DISTRO}" | \cut -f 2 -d ' ' )"
  fi
  return 0
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then

  # shellcheck source=/dev/null

  . "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
fi

__initialize_base_machinemgt
__prepared_base_machinemgt
