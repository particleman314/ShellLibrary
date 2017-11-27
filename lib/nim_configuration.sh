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
# Software Package : Shell Automated Testing -- UIM Configuration
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __configuration_components
#    __copy_configuration_key
#    __get_line_markers_for_section
#    __get_key_from_configuration
#    __modify_rc_data_elements
#    __read_rc_data_element
#    __remove_rc_get_subsection
#    __reset_previous_cycle
#    __spacing_for_key_in_section
#    add_configuration_key
#    add_configuration_section
#    change_configuration_key
#    change_configuration_section_name
#    copy_configuration_key
#    copy_configuration_section
#    get_key_from_configuration
#    get_key_lineno_from_configuration
#    get_section_kvpairs
#    get_subsections
#    has_configuration_section
#    merge_configuration_sections
#    move_configuration_key
#    move_configuration_section
#    remove_configuration_key
#    remove_configuration_section
#
###############################################################################

__key_splitter='|||'
__std_elem_sep=':'
__NO_SECTION_MATCH="0${__std_elem_sep}0"

__REMOVE_LINE=0
__ADD_LINE=1

__configuration_components()
{
  typeset configuration_section="$1"
  [ -z "${configuration_section}" ] && return "${FAIL}"

  typeset components
  components="$( printf "%s\n" "${configuration_section}" | \sed -e 's#/##' -e 's#/# #g' )"
  printf "%s\n" "${components}"

  return "${PASS}"
}

__copy_configuration_key()
{
  __debug $@

  typeset localchannel='hCKTC'

  typeset configuration_file=
  typeset configuration_section=
  typeset new_configuration_section=
  typeset key=
  typeset newkey=
  typeset backup="${NO}"

  typeset RC=
  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: k: key: n: newkey: g: new-cfgsection: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'        ) configuration_file="${OPTARG}";;
    's'|'cfgsection'     ) configuration_section="${OPTARG}";;
    'g'|'new-cfgsection' ) new_configuration_section="${OPTARG}";;
    'k'|'key'            ) key="${OPTARG}";;
    'n'|'newkey'         ) newkey="${OPTARG}";;
    'b'|'backup'         ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"

  [ $( is_empty --str "${key}" ) -eq "${YES}" ] || [ $( is_empty --str "${newkey}" ) -eq "${YES}" ] && return "${FAIL}"

  configuration_section=$( default_value --def "$( remove_extension $( \basename "${configuration_file}" ) )" "${configuration_section}" )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${new_configuration_section}" ) -eq "${YES}" ] && new_configuration_section="${configuration_section}"

  [ "${configuration_section}" == "${new_configuration_section}" ] && [ "${key}" == "${newkey}" ] && return "${FAIL}"

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset bgsect=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset edsect=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )

  [ "${bgsect}" -lt 1 ] || [ "${edsect}" -lt 1 ] && return "${FAIL}"

  typeset keyline=$( __get_key_from_configuration --cfgfile "${configuration_file}" --cfgsection "${configuration_section}" --key "${key}" )
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset result=$( get_element --data "${keyline}" --id 1 --separator "${__std_elem_sep}" )
  typeset lineid=$( get_element --data "${keyline}" --id 2 --separator "${__std_elem_sep}" )

  # If in same section when duplicating a key then use the configuration section
  # markers to determine where to physically insert the line in question
  #
  # Else, need to add the configuration to the new section
  #
  if [ "${configuration_section}" == "${new_configuration_section}" ]
  then
    typeset insertion_line=$(( bgsect + 1 ))

    typeset tmpfile=$( make_temp_file )
    if [ ! -f "${tmpfile}" ]
    then
      discard --channel "${localchannel}"
      return "${FAIL}"
    fi
    register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

    typeset indent=$( __spacing_for_key_in_section "${configuration_section}" )
    if [ $( is_empty --str "${result}" ) -eq "${NO}" ]
    then
      \sed -e "${insertion_line}i${__key_splitter}${indent}${newkey} = ${result}" "${configuration_file}" | \sed -e "s#${__key_splitter}##" > "${tmpfile}"
    else
      \sed -e "${insertion_line}i${__key_splitter}${indent}${newkey} =" "${configuration_file}" | \sed -e "s#${__key_splitter}##" > "${tmpfile}"
    fi

    \mv -f "${tmpfile}" "${configuration_file}"
    discard --channel "${localchannel}"
    return "${PASS}"
  else
    typeset ack_options="--cfgfile $( escapify "${configuration_file}" ) --cfgsection $( escapify "${new_configuration_section}" ) --key $( escapify "${newkey}" )"
    [ "${backup}" -eq "${YES}" ] && ack_options+=' --backup'

    [ $( is_empty --str "${result}" ) -eq "${NO}" ] && ack_options+=" --value $( escapify "${result}" ) "

    add_configuration_key ${ack_options}
    RC=$?
    return "${RC}"
  fi
}

__get_line_markers_for_section()
{
  __debug $@

  typeset localchannel='hGLMFS'

  typeset configuration_file="$1"
  typeset configuration_section="$2"
  shift 2

  typeset offset=0
  typeset startpt=
  typeset endpt=
  
  if [ $# -gt 0 ]
  then
    typeset data="$1"
    typeset maxlines=$( __get_line_count "${configuration_file}" )
    startpt=$( default_value --def $( get_element --data "${data}" --id 1 --separator "${__std_elem_sep}" ) 1 )
    endpt=$( default_value --def $( get_element --data "${data}" --id 2 --separator "${__std_elem_sep}" ) ${maxlines} )
    offset=$( default_value --def $( get_element --data "${data}" --id 3 --separator "${__std_elem_sep}" ) $(( startpt - 1 )) )    
  fi

  typeset components="$( __configuration_components "${configuration_section}" )"
  typeset offset_end=0
  typeset s

  typeset testfile=$( make_temp_file )
  register_tmpfile --filename "${testfile}" --channel "${localchannel}"

  typeset tmpfile=$( make_temp_file )
  if [ ! -f "${tmpfile}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  if [ -n "${startpt}" ]
  then
    copy_file_segment --filename "${configuration_file}" -b ${startpt} -e "${endpt}" --outputfile "${testfile}"
  else
    \cp -f "${configuration_file}" "${testfile}"
  fi

  typeset RC
  typeset count=0

  typeset OLDIFS="${IFS}"
  IFS=$(echo -en "\n\b")
  
  for s in ${components}
  do
    [ $( strindex "${s}" "'" ) -ne "-1" ] && s="${s:1:${#s}-2}"
    \grep -q "<${s}>" "${testfile}" 2>/dev/null
    RC=$?
    if [ "${RC}" -ne 0 ]
    then
      printf "%s\n" "${__NO_SECTION_MATCH}"
      discard --channel "${localchannel}"
      return "${RC}"
    fi
    typeset begin_line=$( \grep -n "<${s}>" "${testfile}" 2>/dev/null | cut -f 1 -d "${__std_elem_sep}" )
    typeset end_line=$( \grep -n "</${s}>" "${testfile}" 2>/dev/null | cut -f 1 -d "${__std_elem_sep}" )

    # Has beginning marker but no corresponding ending marker [ need to check that haven't
    # crossed a section boundary though in the looking process
    if [ -n "${begin_line}" ] && [ -z "${end_line}" ]
    then
      printf "%s\n" "${__NO_SECTION_MATCH}"
      discard --channel "${localchannel}"
      return "${FAIL}"
    fi

    # Has ending marker but no corresponding beginning marker [ need to check that haven't
    # crossed a section boundary though in the looking process
    if [ -z "${begin_line}" ] && [ -n "${end_line}" ] 
    then
      printf "%s\n" "${__NO_SECTION_MATCH}"
      discard --channel "${localchannel}"
      return "${FAIL}"
    fi

    # Make sure not boundary crossing...
    if [ -n "${begin_line}" ] && [ -n "${end_line}" ]
    then
      typeset next_line
      next_line=$(( end_line + 1 ))
      \sed -n "${begin_line},${end_line}p;${next_line}q" "${testfile}" > "${tmpfile}"
      offset=$(( offset + begin_line ))
      \cp -f "${tmpfile}" "${testfile}" 2>/dev/null
    else
      printf "%s" "${__NO_SECTION_MATCH}"
      discard --channel "${localchannel}"
      return "${FAIL}"
    fi
    count=$( increment ${count} )
  done

  IFS="${OLDIFS}"
  
  if [ "${count}" -gt 1 ]
  then
    offset=$(( offset - count + 1 ))
    offset_end=$(( offset - begin_line + end_line ))
  else
    offset_end=${end_line}
  fi

  discard --channel "${localchannel}"

  printf "%s\n" "${offset}${__std_elem_sep}${offset_end}"
  return "${PASS}"
}

__get_key_from_configuration()
{
  __debug $@

  typeset localchannel='hGKFC'
  typeset configuration_file=
  typeset configuration_section=
  typeset key=

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ $( is_empty --str "${key}" ) -eq "${YES}" ] && return "${FAIL}"

  configuration_section=$( default_value --def $( remove_extension $( basename "${configuration_file}" ) ) "${configuration_section}" )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset begin_line=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset end_line=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )

  [ "${begin_line}" -lt 1 ] || [ "${end_line}" -lt 1 ] && return "${FAIL}"

  # Remove spaces and tabs from beginning and ending of line
  typeset modified=$( \sed 's#^[ \t]*##;s#[ \t]*$##' "${configuration_file}" | \tr -d '\r' )

  typeset testfile=$( make_temp_file )
  if [ ! -f "${testfile}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${testfile}" --channel "${localchannel}"

  printf "%s\n" "${modified}" > "${testfile}"

  typeset tmpfile=$( make_temp_file )
  if [ ! -f "${tmpfile}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  \sed -n "${begin_line},${end_line}p" "${testfile}" > "${tmpfile}"
  \mv -f "${tmpfile}" "${testfile}"

  \grep -q "^${key} =" "${testfile}"
  typeset exists=$?
  if [ "${exists}" -ne "${PASS}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi

  typeset result=$( \grep -n "^${key} =" "${testfile}" 2>/dev/null | \tr -s ' ' )
  typeset lineresult=$( printf "%s\n" "${result}" | \cut -f 1 -d ':' )
  result=$( printf "%s\n" "${result}" | \cut -f 3- -d ' ' )
  [ -z "${lineresult}" ] || [ $( is_numeric_data --data "${lineresult}" ) -eq "${NO}" ] && lineresult=0
  [ -z "${begin_line}" ] || [ $( is_numeric_data --data "${begin_line}" ) -eq "${NO}" ] && begin_line=0
  
  lineresult=$(( lineresult + begin_line - 1 ))

  typeset empty="${NO}"
  [ $( is_empty --str "${result}" ) -eq "${YES}" ] && empty="${YES}"
  printf "%s\n" "${result}${__std_elem_sep}${lineresult}${__std_elem_sep}${empty}"

  discard --channel "${localchannel}"
  return "${PASS}"
}

__initialize_nim_configuration()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"
  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"
  __load __initialize_networkmgt "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
 
  __initialize "__initialize_nim_configuration"
}

__modify_rc_data_elements()
{
  typeset filename="$1"
  typeset rc_cnt="$2"
  typeset new_endpt="$3"
  typeset method=${4:-${__ADD_LINE}}

  if [ -f "${filename}" ]
  then
    typeset lineid=$(( rc_cnt + 1 ))
    typeset previous_cycle=$(( rc_cnt - 1 ))
    if [ "${lineid}" -gt 1 ]
    then
      if [ "${method}" -eq "${__ADD_LINE}" ]
      then
        printf "%s\n" "${recursive_count}:${new_endpt}" >> "${filename}"
      else
        if [ "${previous_cycle}" -ge 0 ]
        then
          \cat "${filename}" | \sed "${lineid}d" -e "s#^${previous_cycle}:\(.*\)#${previous_cycle}:${new_endpt}#" > "${filename}.bck"
          \mv -f "${filename}.bck" "${filename}"
        fi
      fi
    else
      if [ "${lineid}" -eq 1 ]
      then
        \cat "${filename}" | \sed -e "s#^${lineid}:\(.*\)#${lineid}:${new_endpt}#" > "${filename}.bck"
        \mv -f "${filename}.bck" "${filename}"
      fi
    fi
  else
    printf "%s\n" "${recursive_count}:${new_endpt}" >> "${filename}"
  fi
}

__prepared_nim_configuration()
{
  __prepared "__prepared_nim_configuration"
}

__read_rc_data_element()
{
  typeset filename="$1"
  typeset id="$2"
  typeset lineid="${3:-1}"

  if [ -z "$( trim "${filename}" )" ] || [ -z "${id}" ]
  then
    printf "%d\n" '0'
    return "${FAIL}"
  fi

  typeset data=$( \sed "${lineid}q;d" "${filename}" )
  #echo "5.5 -- ${data} -- ${id}" >> xyz
  typeset datacomp=$( get_element --data "${data}" --id "${id}" --separator "${__std_elem_sep}" )
  printf "%d\n" "${datacomp}"
  return "${PASS}"
}

__remove_rc_get_subsection()
{
  [ -z "$1" ] && return "${PASS}"
  typeset data=$( printf "%s\n" "$1" | cut -f 1 -d ':' )
  printf "%s\n" "${data}"
  return "${PASS}"
}

__reset_previous_cycle()
{
  typeset filename="$1"
  typeset id="$2"
  typeset lineid="${3:-0}"

  if [ -z "$( trim "${filename}" )" ] || [ -z "${id}" ]
  then
    printf "%d\n" '0'
    return "${FAIL}"
  fi

  typeset counter=0
  typeset rcline
  
  if [ -f "${filename}" ]
  then
    while read -r -u 8 rcline
    do
      typeset level_rc=$( get_element --data "${rcline}" --id 1 --separator "${__std_elem_sep}" )
      [ "${level_rc}" -eq "${id}" ] && continue
      typeset incr_counter=$( get_element --data "${rcline}" --id 2 --separator "${__std_elem_sep}" )
      counter=$(( counter + incr_counter ))
    done 8< "${filename}"
  fi

  counter=$( increment "${counter}" "${lineid}" )
  printf "%d\n" "${counter}"
  return "${PASS}"
}

__spacing_for_key_in_section()
{
  __debug $@

  typeset configuration_section="$1"
  if [ $( is_empty --str "${configuration_section}" ) -eq "${NO}" ]
  then
    #typeset components
    #components=$( printf "%s\n" "${configuration_section}" | sed -e 's#/# #g' )

    typeset maxloop=$( count_items --data "${configuration_section}" --separator '/' )
    get_repeated_char_sequence --count ${maxloop} | \sed -e "s#${__STD_REPEAT_CHAR}#  #g"
  fi
  return "${PASS}"
}

add_configuration_key()
{
  __debug $@

  typeset localchannel='ACK'
  typeset configuration_file=
  typeset configuration_section=
  typeset key
  typeset value
  typeset backup="${NO}"

  typeset RC
  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: k: key: v: value: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
    'v'|'value'      ) value="${OPTARG}";;
    'b'|'backup'     ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"

  [ $( is_empty --str "${key}" ) -eq "${YES}" ] && return "${FAIL}"

  configuration_section=$( default_value --def "${configuration_section}" "$( remove_extension $( \basename "${configuration_file}" ) )" )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset lineid=0
  typeset cfgsection_exists=$( has_configuration_section --cfgfile "${configuration_file}" --cfgsection "${configuration_section}" )
  if [ "${cfgsection_exists}" -eq "${NO}" ]
  then
    add_configuration_section --cfgfile "${configuration_file}" --cfgsection "${configuration_section}"
    RC="$?"
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  else
    lineid=$( get_key_lineno_from_configuration --cfgfile "${configuration_file}" --cfgsection "${configuration_section}" --key "${key}" )
    [ $( is_empty --str "${lineid}" ) -eq "${YES}" ] && lineid=0
  fi

  # Brand new key to add to this configuration section
  if [ "${lineid}" -lt 1 ]
  then
    typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

    typeset beginline=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
    typeset endline=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )

    if [ "${beginline}" -lt "${endline}" ] && [ "${beginline}" -gt 0 ]
    then
      typeset insertion_line=$(( beginline + 1 ))

      typeset tmpfile=$( make_temp_file )
      if [ ! -f "${tmpfile}" ]
      then
        discard --channel "${localchannel}"
        return "${FAIL}"
      fi
      register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

      typeset indent=$( __spacing_for_key_in_section "${configuration_section}" )
      \sed -e "${insertion_line}i${__key_splitter}${indent}${key} = ${value}" "${configuration_file}" | \sed -e "s#${__key_splitter}##" > "${tmpfile}"
      \mv -f "${tmpfile}" "${configuration_file}"
      discard --channel "${localchannel}"
    elif [ "${beginline}" -eq "${endline}" ] && [ "${beginline}" -eq 0 ]
    then
      return "${FAIL}"
    fi
    return "${PASS}"
  else
    typeset cck_options="--cfgfile $( escapify "${configuration_file}" ) --cfgsection $( escapify "${configuration_section}" ) --key $( escapify "${key}" )"
    [ $( is_empty --str "${value}" ) -eq "${NO}" ] && cck_options+=" --value $( escapify "${value}" )"
    change_configuration_key ${cck_options}
    RC=$?
    return "${RC}"
  fi
}

add_configuration_section()
{
  __debug $@

  typeset localchannel='ACS'
  typeset configuration_file=
  typeset configuration_section=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'b'|'backup'     ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && cp -f "${configuration_file}" "${configuration_file}.bak"

  configuration_section=$( default_value --def "${configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset components=$( __configuration_components "${configuration_section}" )
  typeset num_components=$( count_items --data ${components} )

  typeset testfile="${configuration_file}"
  typeset current_path=
  typeset offset=0

  typeset begin_line=0
  typeset end_line=0

  if [ "${num_components}" -gt 0 ]
  then
    typeset tmpfile=$( make_temp_file )
    if [ ! -f "${tmpfile}" ]
    then
      discard --channel "${localchannel}"
      return "${FAIL}"
    fi
    register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

    typeset s=
    for s in ${components}
    do
      typeset markers=$( __get_line_markers_for_section "${testfile}" "${s}" "${begin_line}${__std_elem_sep}${end_line}${__std_elem_sep}${offset}" )
      typeset RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        begin_line=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
        end_line=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )
      fi

      # If the section is not found at this level of the component,
      # then we can safely add from this component downward in scope
      if [ "${markers}" == "${__NO_SECTION_MATCH}" ]
      then
        [ ${offset} -eq 0 ] && offset=1
        typeset entry_point=$(( begin_line + offset ))
        typeset indent=$( __spacing_for_key_in_section "${current_path}" )

        \sed -e "${entry_point}i${__key_splitter}${indent}<${s}>\n${indent}</${s}>" "${testfile}" | \sed -e "s#${__key_splitter}##g" > "${tmpfile}"
        \mv -f "${tmpfile}" "${testfile}"
        offset=$(( entry_point + 1 ))
      else
        offset=$(( offset + end_line ))
      fi
      current_path+="/${s}"
    done

    discard --channel "${localchannel}"
  fi
  return "${PASS}"
}

change_configuration_key()
{
  __debug $@

  typeset localchannel='CCK'
  typeset configuration_file=
  typeset configuration_section=
  typeset key=
  typeset new_value=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: v: value: s: cfgsection: k: key: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
    'v'|'value'      ) new_value="${OPTARG}";;
    'b'|'backup'     ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"
  [ $( is_empty --str "${key}" ) -eq "${YES}" ] && return "${FAIL}"

  configuration_section=$( default_value --def "${configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset lineid=$( get_key_lineno_from_configuration --cfgfile "${configuration_file}" --cfgsection "${configuration_section}" --key "${key}" )
  [ "${lineid}" -lt 1 ] && return "${FAIL}"

  typeset tmpfile=$( make_temp_file )
  if [ ! -f "${tmpfile}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  \sed -e "${lineid}s/\(\w*\)\( = \).*/\1\2${new_value}/" "${configuration_file}" > "${tmpfile}"
  \mv -f "${tmpfile}" "${configuration_file}"

  discard --channel "${localchannel}"
  return "${PASS}"
}

change_configuration_section_name()
{
  __debug $@

  typeset localchannel='CCSN'
  typeset configuration_file=
  typeset old_configuration_section_name=
  typeset new_configuration_section_name=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: n: new-cfgsection:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'         ) configuration_file="${OPTARG}";;
    's'|'cfgsection'      ) old_configuration_section_name="${OPTARG}";;
    'n'|'new-cfgsection'  ) new_configuration_section_name="${OPTARG}";;
    'b'|'backup'          ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && cp -f "${configuration_file}" "${configuration_file}.bak"

  old_configuration_section_name=$( default_value --def "${old_configuration_section_name}" $( remove_extension $( basename "${configuration_file}" ) ) )

  [ $( is_empty --str "${old_configuration_section_name}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${new_configuration_section_name}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset root_section=$( printf "%s\n" "${old_configuration_section_name}" | \sed -e 's#/# #g' | \tr ' ' '\n' | \tail -n 1 )
  typeset new_root_section=$( printf "%s\n" "${new_configuration_section_name}" | \sed -e 's#/# #g' | \tr ' ' '\n' | \tail -n 1 )

  [ "${root_section}" == "${new_root_section}" ] && return "${PASS}"

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${old_configuration_section_name}" )
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset begin_line=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset end_line=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )
  typeset tmpfile=$( make_temp_file )
  if [ ! -f "${tmpfile}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  \sed -e "${begin_line}s#<${root_section}>#<${new_root_section}>#" "${configuration_file}" > "${tmpfile}"
  \mv -f "${tmpfile}" "${configuration_file}"

  \sed -e "${end_line}s#</${root_section}>#</${new_root_section}>#" "${configuration_file}" > "${tmpfile}"
  \mv -f "${tmpfile}" "${configuration_file}"

  discard --channel "${localchannel}"
  return "${PASS}"
}

copy_configuration_key()
{
  __debug $@

  __copy_configuration_key $@
  return $? 
}

copy_configuration_section()
{
  __debug $@

  typeset localchannel='CCS'
  typeset configuration_file=
  typeset configuration_section=
  typeset new_configuration_section=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: n: new-cfgsection: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'         ) configuration_file="${OPTARG}";;
    's'|'cfgsection'      ) configuration_section="${OPTARG}";;
    'n'|'new-cfgsection'  ) new_configuration_section="${OPTARG}";;
    'b'|'backup'          ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"

  configuration_section=$( default_value --def "${configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${new_configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  [ "${markers}" == "${__NO_SECTION_MATCH}" ] && return "${FAIL}"

  [ "${configuration_section}" == "${new_configuration_section}" ] && return "${PASS}"

  typeset begin_line=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset end_line=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )

  next_line="${end_line}"
  begin_line=$( increment "${begin_line}" )
  end_line=$( increment "${end_line}" -1 )

  typeset tmpfile=$( make_temp_file )
  typeset tmpfile2=$( make_temp_file )
  if [ ! -f "${tmpfile}" ] || [ ! -f "${tmpfile2}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"
  register_tmpfile --filename "${tmpfile2}" --channel "${localchannel}"

  \sed -n "${begin_line},${end_line}p;${next_line}q" "${configuration_file}" > "${tmpfile}"

  typeset acs_options="--cfgfile $( escapify "${configuration_file}" ) --cfgsection $( escapify "${new_configuration_section}" )"
  [ "${backup}" -eq "${YES}" ] && acs_options+=' --backup'

  add_configuration_section ${acs_options}
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    discard --channel "${localchannel}"
    return "${RC}"
  fi

  typeset new_markers=$( __get_line_markers_for_section "${configuration_file}" "${new_configuration_section}" )
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    discard --channel "${localchannel}"
    return "${RC}"
  fi

  typeset new_begin_line=$( get_element --data "${new_markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset new_end_line=$( get_element --data "${new_markers}" --id 2 --separator "${__std_elem_sep}" )

  if [ "${new_markers}" == "${__NO_SECTION_MATCH}" ]
  then
    discard --channel "${localchannel}"
    return "${FAIL}"
  fi

  # Need to possibly "re-space" the entries...
  new_begin_line=$( increment "${new_begin_line}" )

  \sed "${new_begin_line}i___MARKER___" "${configuration_file}" -e "/___MARKER___/r ${tmpfile}" -e '/___MARKER___/d' > "${tmpfile2}"
  \mv -f "${tmpfile2}" "${configuration_file}"

  discard --channel "${localchannel}"
  return "${PASS}"
}

get_key_from_configuration()
{
  __debug $@

  typeset keyline=$( __get_key_from_configuration $@ )
  [ $( is_empty --str "${keyline}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset value=$( get_element --data "${keyline}" --id 1 --separator "${__std_elem_sep}" )
  typeset missing_value=$( get_element --data "${keyline}" --id 3 --separator "${__std_elem_sep}" )

  if [ -z "${value}" ]
  then
    if [ "${missing_value}" -eq 1 ]
    then
      return "${PASS}"
    else
      return "${FAIL}"
    fi
  fi
  
  [ -n "${value}" ] && printf "%s\n" "${value}"
  return "${PASS}"
}

get_key_lineno_from_configuration()
{
  __debug $@

  typeset keyline=$( __get_key_from_configuration $@ )
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ] || [ $( is_empty --str "${keyline}" ) -eq "${YES}" ]
  then
    printf "%d\n" 0
    return "${FAIL}"
  fi
  printf "%s\n" $( get_element --data "${keyline}" --id 2 --separator "${__std_elem_sep}" )
  return "${PASS}"
}

get_section_kvpairs()
{
  __debug $@

  typeset localchannel='GSKVpairs'
  typeset configuration_file=
  typeset configuration_section=

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "${markers}" == "${__NO_SECTION_MATCH}" ] && return "${FAIL}"

  typeset tmpfile=$( make_temp_file )
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  copy_file_segment --filename "${configuration_file}" -b $( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" ) -e $( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" ) --outputfile "${tmpfile}"
  typeset pairs=

  if [ -s "${tmpfile}" ]
  then
    typeset line
    while read -r -u 9 line
    do
      line=$( trim "${line}" )
      printf "%s\n" "${line}" | \grep "^<" | \grep -q '>'
      typeset match=$?
      if [ "${match}" -ne "${PASS}" ]
      then
        if [ -z "${pairs}" ]
        then
          pairs=$( printf "%s\n" "${line}" | \sed -e 's#\(.\+\) = \(.\+\)#\1|\2#' )
        else
          pairs+="${__std_elem_sep}$( printf "%s\n" "${line}" | \sed -e 's#\(.\+\) = \(.\+\)#\1|\2#' )"
        fi
      fi
    done 9< "${tmpfile}"
  fi

  discard --channel "${localchannel}"
  printf "%s" "${pairs}"
  return "${PASS}" 
}

get_subsections()
{
  __debug $@

  typeset localchannel='GS'
  typeset configuration_file=
  typeset configuration_section=
  typeset avoid_delete="${NO}"

  typeset current_read_markers=$( get_temp_dir )/.___section_marker___.$$.data

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: a avoid-tmp-delete" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'          ) configuration_file="${OPTARG}";;
    's'|'cfgsection'       ) configuration_section="${OPTARG}";;
    'a'|'avoid-tmp-delete' ) avoid_delete="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  # Global counters ( represents recursive counting )
  typeset recursive_count=0
  typeset counter=0

  [ -f "${current_read_markers}" ] && recursive_count=$( __get_line_count "${current_read_markers}" )

  typeset beginline=0
  typeset endline=0

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ] || [ "${markers}" == "${__NO_SECTION_MATCH}" ]
  then
    #echo "Exiting -- ${recursive_count} -- ${endline}" >> xyz
    __modify_rc_data_elements "${current_read_markers}" "${recursive_count}" "${endline}" "${__REMOVE_LINE}"
    return "${FAIL}"
  fi

  typeset tmpfile=$( make_temp_file )
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  typeset beginline=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset endline=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )
  beginline=$(( beginline + 1 ))
  endline=$(( endline - 1 ))
  copy_file_segment --filename "${configuration_file}" -b ${beginline} -e ${endline} --outputfile "${tmpfile}"

  #echo "1.0 -- ${configuration_section} -- ${recursive_count} -- ${counter} -- ${markers} -- ${beginline} -- ${endline}" >> xyz
  #cat "${tmpfile}" >> xyz
  #pause

  typeset pairs=
  if [ -s "${tmpfile}" ]
  then
    typeset line
    typeset linecounter=0
    while read -r -u 9 line
    do
      linecounter=$(( linecounter + 1 ))

      [ "${counter}" -gt "${linecounter}" ] && continue
      line=$( trim "${line}" )

      printf "%s\n" "${line}" | \grep "^<" | \grep -v "^</" | \grep -q '>'
      typeset match=$?

      #echo "1.1.5 -- ${linecounter} -- ${line} -- ${match}" >> xyz
      #pause

      if [ "${match}" -eq "${PASS}" ]
      then
        typeset subsection=$( printf "%s\n" "${line}" | \sed -e 's#<\(.*\)>#\1#' )
        #echo "1.2 -- ${subsection} -- ${recursive_count} -- ${linecounter} -- ${counter} << ${pairs} >>" >> xyz
        #pause

        __modify_rc_data_elements "${current_read_markers}" "${recursive_count}" "${linecounter}" "${__ADD_LINE}"
        #cat "${current_read_markers}" >> xyz
        #pause
        typeset deepdive=$( get_subsections --cfgfile "${tmpfile}" --cfgsection "${subsection}" -a )
        #echo "1.2.5 -- ${deepdive} -- ${recursive_count} -- ${linecounter}" >> xyz
        #pause
        counter=$( __read_rc_data_element "${current_read_markers}" 2 "$(( recursive_count + 1 ))" )
        #echo "1.2.5.1 -- reset ${counter}" >> xyz
        #cat "${current_read_markers}" >> xyz 
        #pause
        typeset dds
        for dds in ${deepdive}
        do
          typeset receiver_level=$( get_element --data "${dds}" --id 2 --separator "${__std_elem_sep}" )
          typeset diff=$(( receiver_level - recursive_count ))
          if [ "${diff}" -lt 2 ]
          then
            #echo "1.3 -- ${dds}" >> xyz
            #pause
            typeset latest_pair=$( __remove_rc_get_subsection "${configuration_section}/${dds}" )
            if [ -z "${pairs}" ]
            then
              pairs="${latest_pair}:${recursive_count}"
            else
              pairs+=" ${latest_pair}:${recursive_count}"
            fi
          fi
        done
        typeset latest_pair=$( __remove_rc_get_subsection "${configuration_section}/${subsection}" )
        if [ -z "${pairs}" ]
        then
           pairs="${latest_pair}:${recursive_count}"
        else
           pairs+=" ${latest_pair}:${recursive_count}"
        fi
        #echo "1.2.7 -- ${pairs}" >> xyz
      fi
    done 9< "${tmpfile}"
  fi

  if [ "${recursive_count}" -eq 0 ]
  then
    if [ -n "${pairs}" ]
    then
      pairs=$( printf "%s\n" ${pairs} | \grep ':0' | \tr '\n' ' ' | \sed -e 's#:0##g' )
      pairs=$( trim "${pairs}" )
    fi
  fi
  #echo "1.4 -- <${pairs}>" >> xyz
  [ "${avoid_delete}" -eq "${NO}" ] && discard --channel "${localchannel}"

  #[ "${recursive_count}" -gt 0 ] && printf "%s\n" "${recursive_count}:${linecounter}" >> "${current_read_markers}"
  #echo "1.4.1 -- ${recursive_count}" >> xyz
  typeset updated_endpoint=$( __reset_previous_cycle "${current_read_markers}" "${recursive_count}" "$(( linecounter + recursive_count + 1 ))" )
  #echo "1.4.2 -- ${updated_endpoint}" >> xyz
  #pause
  #cat "${current_read_markers}" >> xyz
  #echo "(B) ------" >> xyz
  __modify_rc_data_elements "${current_read_markers}" "${recursive_count}" "${updated_endpoint}" "${__REMOVE_LINE}" 
  #cat "${current_read_markers}" >> xyz
  #echo "(A) ------" >> xyz
  #pause

  printf "%s" "${pairs}"
  return "${PASS}"
}

has_configuration_section()
{
  __debug $@

  typeset configuration_file=
  typeset configuration_section=

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] || [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ]
  then
    print_no
    return "${PASS}"
  fi

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
    return "${PASS}"
  fi

  typeset beginline=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  if [ "${beginline}" -gt 0 ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

merge_configuration_sections()
{
  __debug $@

  typeset localchannel='MeCS'
  typeset configuration_file=
  typeset old_configuration_section=
  typeset new_configuration_section=
  typeset backup="${NO}"

  typeset RC=

  OPTIND=1
  while getoptex "f: cfgfile: cfgsection1: cfgsection2: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'        ) configuration_file="${OPTARG}";;
        'cfgsection1'    ) old_configuration_section="${OPTARG}";;
        'cfgsection2'    ) new_configuration_section="${OPTARG}";;
    'b'|'backup'         ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ "${backup}" -eq "${YES}" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"

  old_configuration_section=$( default_value --def "${old_configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )

  [ $( is_empty --str "${old_configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${new_configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  [ "${old_configuration_section}" == "${new_configuration_section}" ] && return "${PASS}"

  typeset kvpairs=$( get_section_kvpairs --cfgfile "${configuration_file}" --cfgsection "${old_configuration_section}" )
  typeset k
  for k in ${kvpairs}
  do
    typeset key=$( get_element --data "${k}" --id 1 --separator ':' )
    typeset val=$( get_element --data "${k}" --id 2 --separator ':' ) 

    add_configuration_key --cfgfile "${configuration_file}" --cfgsection "${old_configuration_section}" --key "${key}" --value "${val}"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  done

  typeset subsections=$( get_subsections --cfgfile "${configuration_file}" --cfgsection "${old_configuration_section}" )
  typeset s
  for s in ${subsections}
  do
    typeset subsect_exists=$( has_configuration_section --cfgfile "${configuration_file}" --cfgsection "${new_configuration_section}/${s}" )
    if [ "${subsect_exists}" -eq "${YES}" ]
    then
      merge_configuration_sections --cfgfile "${configuration_file}" --cfgsection1 "${old_configuration_section}/${s}" --cfgsection2 "${new_configuration_section}/${s}"
      RC=$?
      [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    fi
  done
}

move_configuration_key()
{
  __debug $@

  #echo "ORIGINAL _CMDLINE_ --> $@" >> xyz
  copy_configuration_key $@
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset reduced_cmdline=$( remove_option 2 new-cfgsection:1:1 newkey:1:1 $@ )
  #echo "REDUCED _CMDLINE_ --> ${reduced_cmdline}" >> xyz
  remove_configuration_key ${reduced_cmdline}
  return $?
}

move_configuration_section()
{
  __debug $@

  typeset localchannel='MCS'
  typeset configuration_file=
  typeset old_configuration_section=
  typeset new_configuration_section=
  typeset backup="${NO}"

  typeset RC=

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: n: new-cfgsection: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'        ) configuration_file="${OPTARG}";;
    's'|'cfgsection'     ) old_configuration_section="${OPTARG}";;
    'n'|'new-cfgsection' ) new_configuration_section="${OPTARG}";;
    'b'|'backup'         ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}" 
  [ "${backup}" -eq "${YES}" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"

  old_configuration_section=$( default_value --def "${old_configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )

  [ $( is_empty --str "${old_configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${new_configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset new_cfg_exists=$( has_configuration_section --cfgfile "${configuration_file}" --cfgsection "${new_configuration_section}" )
  if [ "${new_cfg_exists}" -eq "${YES}" ]
  then
    merge_configuration_sections --cfgfile "${configuration_file}" --cfgsection1 "${old_configuration_section}" --cfgsection2 "${new_configuration_section}"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  else
    copy_configuration_section --cfgfile "${configuration_file}" --cfgsection "${old_configuration_section}" --new-cfgsection "${new_configuration_section}"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  fi

  remove_configuration_section --cfgfile "${configuration_file}" --cfgsection "${old_configuration_section}"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  #cat "${configuration_file}" >> xyz
  return "${PASS}"
}

remove_configuration_key()
{
  __debug $@

  typeset localchannel='RCK'
  typeset configuration_file=
  typeset configuration_section=
  typeset key=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: k: key: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
    'b'|'backup'     ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ $( is_empty --str "${key}" ) -eq "${YES}" ] && return "${FAIL}"

  configuration_section=$( default_value --def "${configuration_section}" $( remove_extension $( basename "${configuration_file}" ) ) )
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset lineid=$( get_key_lineno_from_configuration --cfgfile "${configuration_file}" --cfgsection "${configuration_section}" --key "${key}" )
  [ "${lineid}" -lt 1 ] && return "${FAIL}"

  typeset tmpfile=$( make_temp_file )
  register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

  \sed "${lineid}d" "${configuration_file}" > "${tmpfile}"

  [ "${backup}" -eq "${YES}" ] && [ ! -f "${configuration_file}.bak" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"
  \mv -f "${tmpfile}" "${configuration_file}"  

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    discard --channel "${localchannel}"
    return "${PASS}"
  fi

  typeset begin_line=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset end_line=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )
  begin_line=$( increment ${begin_line} )

  [ "${begin_line}" -eq "${end_line}" ] && remove_configuration_section --cfgfile "${configuration_file}" --cfgsection "${configuration_section}"

  discard --channel "${localchannel}"
  return "${PASS}"
}

remove_configuration_section()
{
  __debug $@

  typeset localchannel='RCS'
  typeset configuration_file=
  typeset configuration_section=
  typeset backup="${NO}"

  OPTIND=1
  while getoptex "f: cfgfile: s: cfgsection: b backup" "$@"
  do
    case "${OPTOPT}" in
    'c'|'cfgfile'    ) configuration_file="${OPTARG}";;
    's'|'cfgsection' ) configuration_section="${OPTARG}";;
    'b'|'backup'     ) backup="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${configuration_file}" ) -eq "${YES}" ] || [ ! -f "${configuration_file}" ] && return "${FAIL}"
  [ $( is_empty --str "${configuration_section}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset markers=$( __get_line_markers_for_section "${configuration_file}" "${configuration_section}" )
  [ $( is_empty --str "${markers}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset beginline=$( get_element --data "${markers}" --id 1 --separator "${__std_elem_sep}" )
  typeset endline=$( get_element --data "${markers}" --id 2 --separator "${__std_elem_sep}" )

  if [ "${beginline}" -ne "${endline}" ] && [ "${beginline}" -gt 0 ] && [ "${endline}" -gt 0 ]
  then
    typeset tmpfile=$( make_temp_file )
    register_tmpfile --filename "${tmpfile}" --channel "${localchannel}"

    \sed -e "${beginline},${endline}d" "${configuration_file}" > "${tmpfile}"
    [ "${backup}" -eq "${YES}" ] && [ ! -f "${configuration_file}.bak" ] && \cp -f "${configuration_file}" "${configuration_file}.bak"
    \mv -f "${tmpfile}" "${configuration_file}"
    discard --channel "${localchannel}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_FUNCTIONDIR}/filemgt.sh"
  . "${SLCF_SEHLL_FUNCTIONDIR}/numerics.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/networkmgt.sh"
fi

__initialize_nim_configuration
__prepared_nim_configuration
