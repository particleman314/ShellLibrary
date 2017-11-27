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
# Software Package : Shell Automated Testing -- Network Functionality
# Application      : Product Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __determine_nic_id
#    __get_support_ipv_key
#    __supports_ipv
#    add_to_ip
#    configure_network_adapter
#    disable_network_adapter
#    enable_network_adapter
#    get_hostfile
#    get_initd_directory
#    get_loopback_adapter_types
#    get_machine_ip
#    get_network_adapter_types
#    get_network_adapters_by_type
#    get_network_adapters_by_ipv_type
#    get_network_adapter
#    get_network_directory
#    get_virtual_ips
#    is_host_alive
#    is_ip_addr
#    is_network_disabled
#    is_network_running
#    translate_ip_format
#
###############################################################################

__determine_nic_id()
{
  [ -z "$1" ] && return "${FAIL}"

  typeset entry="$( get_element --data "$1" --id 1 )"
  entry=$( trim "${entry}" )

  typeset last_char="${entry:$((${#entry}-1)):1}"
  [ "${last_char}" == ':' ] && entry="${entry%?}"
  [ -n "${entry}" ] && printf "%s\n" "${entry}"
  return "${PASS}"
}

__get_support_ipv_key()
{
  typeset ipv="$1"
  [ -z "${ipv}" ] && ipv=4

  typeset key=
  case "${ipv}" in
  '4' ) key='inet';;
  '6' ) key='inet6';;
  esac

  [ -n "${key}" ] && printf "%s\n" "${key}"
  return "${PASS}"
}

__initialize_networkmgt()
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

  __ip_dot_notation_regex='__'

  . "${SLCF_SHELL_FUNCTIONDIR}/network_assertions.sh"

  __initialize "__initialize_networkmgt"
}

__prepared_networkmgt()
{
  __prepared "__prepared_networkmgt"
}

__supports_ipv()
{
  typeset ipv=4
  typeset filename=

  OPTIND=1
  while getoptex "i: ipv: f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv'      ) ipv="${OPTARG}";;
    'f'|'filename' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${filename}" ) -eq "${YES}" ] || [ ! -f "${filename}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset key=$( __get_support_ipv_key ${ipv} )
  if [ -z "${key}" ]
  then
    print_no
    return "${FAIL}"
  fi

  \grep -q "^${key}\b" "${filename}"
  typeset RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

add_to_ip()
{
  __debug $@

  typeset ip=
  typeset offset=
  typeset octet=
  typeset is_ipv4="${YES}"

  OPTIND=1
  while getoptex "i: ip: o: offset: octet: ipv:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ip'       ) ip="${OPTARG}";;
    'o'|'offset'   ) offset="${OPTARG}";;
        'octet'    ) octet="${OPTARG}";;
        'ipv'      ) if [ "${OPTARG}" -eq 6 ]; then is_ipv4="${NO}"; fi;;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Only support IPv4 at the moment
  ###
  return "${PASS}"
}

configure_network_adapter()
{
  __debug $@

  typeset na=
  typeset dryrun="${NO}"
  typeset mode=

  OPTIND=1
  while getoptex "a: adapter: d: dryrun: mode:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'adapter'   ) na="${OPTARG}";;
    'd'|'dryrun'    ) dryrun="${YES}";;
    'm'|'mode'      ) mode="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${mode}" ] && return "${FAIL}"

  typeset networkdir=$( get_network_directory )

  # Need to handle this for different OS types...
  # may need to case this out as separate subfunctions
  [ -z "${na}" ] || [ ! -f "${networkdir}/ifcfg-${na}" ] && return "${FAIL}"

  typeset adminmode=
  if [ "${dryrun}" -eq "${NO}" ]
  then
    case "${OSVARIETY}" in
    'linux'|'solaris'|'aix'|'hp' )
                    if [ "$( to_lower "${mode}" )" == 'up' ];
                    then
                      adminmode='up';
                    else
                      adminmode='down';
                    fi;
                    "${networkdir}/if${adminmode}-eth" "ifcfg-${na}" > /dev/null 2>&1;;
    'windows'|'cygwin'           )
                    if [ "$( to_lower "${mode}" )" == 'up' ];
                    then
                      adminmode='enabled';
                    else
                      adminmode='disabled';
                    fi;
                    netsh interface set interface name="${na}" admin="${adminmode}";;
    esac
  fi

  sleep_func -s 2 --old-version
  return "${PASS}"
}

disable_network_adapter()
{
  configure_network_adapter --mode 'down' $@
  return $?
}

enable_network_adapter()
{
  configure_network_adapter --mode 'up' $@
  return $?
}

get_hostfile()
{
  __debug $@

  typeset linux_type=$( to_lower "$( __get_linux_variety )" )

  if [ "${linux_type}" == 'unknown' ]
  then
    case "${OSVARIETY}" in
    'solaris'          ) printf "%s\n" '/etc/inet/hosts';;
    'windows'|'cygwin' ) printf "%s\n" '/cygdrive/c/Windows/System32/drivers/etc/hosts';;
    *                  ) printf "%s\n" '/etc/hosts';;
    esac
    return "${PASS}"
  fi

  case "${linux_type}" in
  'redhat' | 'debian' | 'ubuntu' | 'centos' | 'suse' ) printf "%s\n" '/etc/hosts'; return "${PASS}";;
  esac

  return "${FAIL}"
}

get_initd_directory()
{
  __debug $@

  typeset linux_type=$( to_lower $( __get_linux_variety ) )

  if [ "${linux_type}" == 'unknown' ]
  then
    printf "%s\n" '/etc/init.d'
    return "${PASS}"
  fi

  case "${linux_type}" in
  'redhat' | 'debian' | 'ubuntu' | 'centos' | 'suse' ) printf "%s\n" '/etc/init.d'; return "${PASS}";;
  esac

  return "${FAIL}"
}

get_loopback_adapter_types()
{
  __debug $@

  typeset ipv=4
  typeset RC="${PASS}"

  OPTIND=1
  while getoptex "i: ipv:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv' ) ipv="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset loopback_adapters
  typeset adapters=$( get_network_adapter_types )
  typeset a
  for a in ${adapters}
  do
    strstr 'lo' "${a}"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      typeset nicfile=$( find_output_file --channel "NIC_${a}" )
      __add_junk_file "${nicfile}"
      [ -n "${nicfile}" ] && [ -f "${nicfile}" ] && [ $( __supports_ipv --ipv ${ipv} --filename "${nicfile}" ) -eq "${YES}" ] && loopback_adapters+=" ${a}"
    fi
  done

  [ -n "${loopback_adapters}" ] && print_plain --message "${loopback_adapters}"

  return "${PASS}"
}

get_machine_ip()
{
  __debug $@

  typeset ipv=4
  typeset selection=
  typeset ipv6_type='global'

  OPTIND=1
  while getoptex "i: ipv: s: selection: scope:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv'       ) ipv="${OPTARG}";;
    's'|'selection' ) selection="${OPTARG}";;
        'scope'     ) ipv6_type="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset nic_adapters="$( get_network_adapter_types )"

  typeset nla
  for nla in ${nic_adapters}
  do
    [ -n "${selection}" ] && [ "${nla}" != "${selection}" ] && continue
    typeset nicfile=$( find_output_file --channel "NIC_${nla}" )

    if [ -n "${nicfile}" ] && [ -f "${nicfile}" ] && [ $( __supports_ipv --ipv "${ipv}" --filename "${nicfile}" ) -eq "${YES}" ]
    then 
      typeset key=$( __get_support_ipv_key ${ipv} )
      if [ -z "${key}" ]
      then
        remove_output_file --channel "NIC_${nla}"
        continue
      fi

      __add_junk_file "${nicfile}"

      typeset add_on_grep
      if [ "${key}" == 'inet6' ]
      then
        typeset lv=$( to_lower $( __get_linux_variety ) )
        case "${lv}" in
        * ) add_on_grep="grep -i 'scope:${ipv6_type}' |"
        esac
      fi
      typeset result=$( grep "^${key}\b" "${nicfile}" | ${add_on_grep} cut -f 2 -d ' ' | sed -e 's#addr: *##' )
      [ -n "${result}" ] && printf "%s\n" "${result}"
      return "${PASS}"
    fi
  done

  return "${FAIL}"
}

get_network_adapter_types()
{
  __debug $@

  # Need to see if there is a common thread amongst the different platforms which
  # can be used to gather this information robustly and consistently

  typeset line=
  typeset count=0
  typeset header=
  typeset adapters=

  typeset adapter_data=

  typeset tmpfile=$( make_temp_file )
  typeset channel=$( make_unique_channel_name --prefix 'IFCONFIG' )

  register_tmpfile --filename "${tmpfile}" --channel "${channel}"

  if [ "${OSVARIETY}" != 'windows' ]
  then
    \ifconfig -a > "${tmpfile}" 2>&1 
    while read -r -u 9 line
    do
      count=$( increment "${count}" )
      line=$( trim "${line}" )
      if [ $( is_empty --str "${line}" ) -eq "${YES}" ]
      then
        typeset nicid=$( __determine_nic_id "${header}" )
        adapters+=" ${nicid}"
        typeset adapterfile=$( find_output_file --channel "NIC_${nicid}" )
        if [ $( is_empty --str "${adapterfile}" ) -eq "${YES}" ]
        then
          typeset adapterfile=$( make_output_file --channel "NIC_${nicid}" --prefix "${nicid}_$$" )
          append_output --data "${adapter_data}" --channel "NIC_${nicid}" --raw
          \tr '|' '\n' < "${adapterfile}" > "${adapterfile}.bak"
          \mv -f "${adapterfile}.bak" "${adapterfile}"
        fi
        adapter_data=
        header=
        count=0
        continue
      fi

      [ "${count}" -eq 1 ] && header="${line}"
      adapter_data+="${line}|"
    done 9<"${tmpfile}"
  else
     \ipconfig > "${tmpfile}" 2>&1 
     while read -r -u 9 line
     do
       true       
     done 9<"${tmpfile}"
  fi

  [ -n "${adapters}" ] && printf "%s\n" ${adapters}
  discard --channel "${channel}"
  return "${PASS}"
}

get_network_adapters_by_type()
{
  __debug $@

  typeset selection=

  OPTIND=1
  while getoptex "s: selection:" "$@"
  do
    case "${OPTOPT}" in
    's'|'selection' ) selection="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${selection}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset all_adapters=$( get_network_adapter_types )
  typeset matched_adapters=$( printf "%s\n" ${all_adapters} | \grep "${selection}" )  

  print_plain --message "${matched_adapters}"
  return "${PASS}"
}

get_network_adapters_by_ipv_type()
{
  __debug $@

  typeset ipv=4
  typeset RC=${PASS}

  OPTIND=1
  while getoptex "i: ipv:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv' ) ipv="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset nicchannel=$( make_unique_channel_name --prefix 'NIC' )
  typeset nicfile=$( make_output_file --channel "${nicchannel}" --prefix 'NIC' )

  register_tmpfile --filename "${nicfile}" --channel "${nicchannel}"

  typeset data=$( \ifconfig -a 2>&1 )
  append_output --channel "${nicchannel}" --data "${data}" --raw

  typeset nic_section_markers=$( \grep -n 'flags' "${nicfile}" | \tr -s ' ' | \tr ' ' ':' | \cut -f 1,2 -d ':' | \tr '\n' ' ' )
  if [ -z "${nic_section_markers}" ]
  then
    nic_section_markers=$( \grep -n 'Link encap' "${nicfile}" | \tr -s ' ' |\ tr ' ' ':' | \cut -f 1,2 -d ':' | \tr '\n' ' ' )
  fi
  nic_cnt=$( __get_line_count "${nicfile}" )
  nic_section_markers+=" ${nic_cnt}:__END__"

  typeset lineid
  typeset begin_line
  typeset end_line

  typeset nictype_files=
  typeset nictype=

  for lineid in ${nic_section_markers}
  do
    typeset current_nicline=$( get_element --data "${lineid}" --id 1 --separator ':' )
    typeset current_nictype=$( trim "$( get_element --data "${lineid}" --id 2 --separator ':' )" )

    if [ -z "${begin_line}" ]
    then
      begin_line="${current_nicline}"
      nictype="${current_nictype}"
      continue
    else
      end_line=$(( current_nicline - 1 ))
      typeset outfile=$( find_output_file --channel "NIC_${nictype}" )
      if [ $( is_empty --str "${outfile}" ) -eq "${YES}" ]
      then
        outfile=$( make_output_file --channel "NIC_${nictype}" --prefix "$$_nic_${nictype}" )
        copy_file_segment --filename "${nicfile}" --beginline ${begin_line} --endline ${end_line} --outputfile "${outfile}"
        begin_line="${current_nicline}"
      fi
      nictype_files+=" ${nictype}:${outfile}"
      nictype="${current_nictype}"
    fi
  done

  typeset match_types=
  typeset f

  typeset key=$( __get_support_ipv_key "${ipv}" )
  [ -z "${key}" ] && return "${FAIL}"

  for f in ${nictype_files}
  do
    nictype=$( get_element --data "${f}" --id 1 --separator ':' )
    sub_nicfile=$( trim "$( get_element --data "${f}" --id 2 --separator ':' )" )

    while read -r -u 9 line
    do
      line=$( trim "${line}" )
      printf "%s\n" "${line}" | grep -q "^${key}\b"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        match_types+=" ${nictype}"
        break
      fi
    done 9<"${sub_nicfile}"
  done

  match_types=$( printf "%s\n" ${match_types} )
  print_plain --message "${match_types}"
  discard --channel "NIC_$$"

  return "${PASS}"
}

get_network_adapter()
{
  __debug $@

  typeset ipv=4
  typeset ip=

  OPTIND=1
  while getoptex "i: ipv: a: address:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv'       ) ipv="${OPTARG}";;
    'a'|'address'   ) ip="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset found_adapters
  if [ $( is_empty --str "${ipv}" ) -eq "${YES}" ]
  then
    found_adapters=$( get_network_adapter_types )
  else
    found_adapters=$( get_network_adapters_by_ipv_type --ipv "${ipv}" )
  fi

  [ $( is_empty --str "${found_adapters}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset non_loopback=$( printf "%s\n" "${found_adapters}" | \grep -v 'lo' )
  if [ -n "${ip}" ]
  then
    typeset n
    for n in ${non_loopback}
    do
      typeset nic_ip=$( get_machine_ip --adapter "${n}" )
      if [ "${nic_ip}" == "${ip}" ]
      then
        printf "%s\n" "${n}"
        return "${PASS}"
      fi
    done
  else
    printf "%s\n" $( get_element --data "${non_loopback}" --id 1 --separator ' ' )
  fi
  return "${PASS}"
}

get_network_directory()
{
  __debug $@

  typeset linux_type=$( to_lower $( __get_linux_variety ) )
  if [ $( is_empty --str "${linux_type}" ) -eq "${YES}" ]
  then
    printf "%s\n" '/etc/sysconfig/network-scripts'
    return "${PASS}"
  fi
  
  case "${linux_type}" in
  'redhat' | 'centos' | 'suse' ) printf "%s\n" '/etc/sysconfig/network-scripts'; return "${PASS}";;
  'debian' | 'ubuntu'          ) printf "%s\n" '/etc/network/interfaces.d'; return "${PASS}";;
  esac

  return "${FAIL}"
}

get_virtual_ips()
{
  __debug $@

  typeset virtips=
  typeset ipv=4
  typeset RC=${PASS}

  OPTIND=1
  while getoptex "i: ipv:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv' ) ipv="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset network_adapters=$( get_network_adapter_types )
  typeset na
  for na in ${network_adapters}
  do
    strstr ':' "${na}"
    RC=$?
    [ "${RC}" -eq "${PASS}" ] && virtips+=" ${na}"
  done

  virtips=$( printf "%s\n" ${virtips} )
  print_plain --message "${virtips}"
  return "${PASS}"
}

is_host_alive()
{
  __debug $@

  typeset RC=
  typeset default_count=5
  typeset host=
  typeset count="${default_count}"
  typeset threshold=0.80

  OPTIND=1
  while getoptex "h: host: c: ping-count: t: threshold:" "$@"
  do
    case "${OPTOPT}" in
    'h'|'host'        ) host="${OPTARG}";;
    'c'|'ping-count'  ) count="${OPTARG}";;
    't'|'threshold'   ) threshold="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ $( is_empty --str "${host}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_numeric_data --data "${count}" ) -eq "${NO}" ] && count="${default_count}"
  [ "${count}" -lt 1 ] && count="${default_count}"

  make_executable --exe 'ping'
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset ping_output=
  
  case "${OSVARIETY}" in
  'linux'   ) ping_output=$( "${ping_exe}" -c "${count}" "${host}" 2>&1 );;
  'solaris' ) ping_output=$( "${ping_exe}" -s "${host}" 64 "${count}" );;
  esac

  RC=$?
  ###
  ### TODO : Need to use a non GNU grep version to do this work....
  ###
  #printf "%s\n" "${ping_output}" | \grep -A 2 "ping statistics" | \grep -q "0% packet loss"
  #typeset RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  
  return "${PASS}"
}

is_ip_addr()
{
  __debug $@

  typeset ipv=4
  typeset ip=

  OPTIND=1
  while getoptex "i: ipv: a: address:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ipv'       ) ipv="${OPTARG}";;
    'a'|'address'   ) ip="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${ip}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset components
  if [ "${ipv}" -eq 4 ]
  then
    components=$( __get_word_count "$( printf "%s" "${ip}" | \sed -e 's#\.# #g' )" )
    if [ "${components}" -eq 4 ]
    then
      print_yes
    else
      print_no
    fi
  else
    components=$( __get_word_count "$( printf "%s" "${ip}" | \sed -e 's#:# #g' )" )
    print_yes
  fi

  return "${PASS}"
}

is_network_disabled()
{
  __debug $@

  typeset adapter=

  OPTIND=1
  while getoptex "a: adapter:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'adapter'   ) adapter="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${adapter}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset found="$( get_network_adapter_types | \grep "${adapter}" )"
  if [ -z "${found}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

is_network_running()
{
  __debug $@

  typeset selection=

  OPTIND=1
  while getoptex "a: adapter:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'adapter' ) selection="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${selection}" ) -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset adapters=$( get_network_adapter_types )
  typeset n
  for n in ${adapters}
  do
    [ "${n}" != "${selection}" ] && continue
    typeset nicfile=$( find_output_file --channel "NIC_${n}" )
    if [ -n "${nicfile}" ] && [ -f "${nicfile}" ]
    then
      \grep -q 'UP' "${nicfile}"
      typeset RC1=$?
      \grep -q 'RUNNING' "${nicfile}"
      typeset RC2=$?
      if [ "${RC1}" -eq "${PASS}" ] && [ "${RC2}" -eq "${PASS}" ]
      then
        print_yes
        return "${PASS}"
      fi
    fi
  done

  print_no
  return "${PASS}"
}

translate_ip_format()
{
  typeset ip="$1"
  typeset convert_dir='forward'
  shift 2
  
  [ $( is_ip_addr --ipv 4 --addr "${ip}" ) -ne "${YES}" ] && return "${FAIL}"
  
  if [ "${convert_dir}" -eq 'forward' ]
  then
    printf "%s\n" "${ip}" | \sed -e "s#\.#${__ip_dot_notation_regex}#g"
  else
    printf "%s\n" "${ip}" | \sed -e "s#${__ip_dot_notation_regex}#\.#g"
  fi
  
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_FUNCTIONDIR}/execaching.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/machinemgt.sh"
fi

__initialize_networkmgt
__prepared_networkmgt
