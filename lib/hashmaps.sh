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
## @Software Package : Shell Automated Testing -- Associated Maps
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.52
#
###############################################################################

###############################################################################
#
# Functions Supplied :
#
#    __access_data
#    __decode_mapname
#    __decode_mapitem
#    __encode_mapitem
#    __get_key_name
#    __get_value_item_separator
#    __set_value_item_separator
#    haccess_keys_via_file
#    haccess_entry_via_file
#    hadd_entry_via_file
#    hadd_item
#    hassign
#    hchange_entry_via_file
#    hclear
#    hcontains_entry_via_file
#    hcontains
#    hcount
#    hdec
#    hdel_item
#    hdel
#    henable_global
#    hexists
#    hexists_map
#    hexport
#    hget
#    hget_mapname
#    hinc
#    hkeys
#    hpersist
#    hprint
#    hput
#    hread_map
#    hreverse_map
#    hunassign
#    hunexport
#    huniquify
#    hupdate
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2068,SC2140,SC2163,SC2086,SC2181

if [ -z "${__MAP_ITEM_SEPARATOR}" ]
then
  __MAP_ITEM_SEPARATOR='|'
  __KEY_SEPARATOR=':::'
  __ALLOW_MULTIMAP=0
  __EXPORT_KEY='all_keys_exported'
  __VALUE_ITEM_SEPARATOR='SSS'
fi

__access_data()
{
  typeset mapname=
  typeset mapfile=
  typeset key=
  typeset access_opts=
  typeset hook=
  
  OPTIND=1
  while getoptex "m: map: f: mapfile: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'      )  mapname="${OPTARG}"; access_opts+=" --map ${mapname}"; hook='hget';;
    'f'|'mapfile'  )  mapfile="${OPTARG}"; access_opts+=" --filename \"${mapfile}\""; hook='haccess_entry_via_file';;
    'k'|'key'      )  key="${OPTARG}"; access_opts+=" --key ${key}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -n "${hook}" ]
  then
    typeset result=
    eval "result=\$( ${hook} ${access_opts} )"
    printf "%s\n" "${result}"
  fi
  return "${PASS}"
}

__decode_mapname()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"

  printf "%s\n" "${input}" | \cut -f 1 -d '=' | \cut -f 2 -d ':' | \sed -e 's#keys$##'
  return "${PASS}"
}

__decode_mapitem()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"

  typeset decode_result="$( printf "%s\n" "${input}" | \cut -f 2 -d '=' | \sed -e 's#^"##' -e 's#"$##' -e "s#${__VALUE_ITEM_SEPARATOR}# #g" )"
  printf "%s\n" "${decode_result}"
  return "${PASS}"  
}

__encode_mapitem()
{
  typeset input="$@"
  [ -z "${input}" ] && return "${FAIL}"

  typeset encode_result="$( printf "%s\n" "${input}" | \sed -e "s# #${__VALUE_ITEM_SEPARATOR}#g" )"
  printf "%s\n" "${encode_result}"
  return "${PASS}"  
}

__get_key_name()
{
  typeset mapname="$1"
  typeset keyname="$2"
  
  [ -z "${mapname}" ] || [ -z "${keyname}" ] && return "${FAIL}"
  printf "%s\n" "${mapname}${keyname}"
  return "${PASS}"
}

__get_value_item_separator()
{
  [ -n  "${__VALUE_ITEM_SEPARATOR}" ] && printf "%s\n" "${__VALUE_ITEM_SEPARATOR}"
  return "${PASS}"
}

__initialize_hashmaps()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  __load __initialize_base_logging "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"
  __initialize "__initialize_hashmaps"
}

__prepared_hashmaps()
{
  __prepared "__prepared_hashmaps"
}

__set_value_item_separator()
{
  [ -n "$1" ] && __VALUE_ITEM_SEPARATOR="$1"
  return "${PASS}"
}

haccess_keys_via_file()
{
  __debug $@

  typeset filename=
  
  OPTIND=1
  while getoptex "f: filename: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'    ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  typeset keys="$( \grep "^KEYS" "${filename}" )"
  keys="$( __decode_mapitem "${keys}" )"
  [ -z "${keys}" ] && return "${FAIL}"
  
  printf "%s\n" "${keys}"
  return "${PASS}"
}

haccess_entry_via_file()
{
  __debug $@

  typeset filename=
  typeset key=
  
  OPTIND=1
  while getoptex "f: filename: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'    ) filename="${OPTARG}";;
    'k'|'key'         ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset mapname="$( \grep "^KEYS" "${filename}" )"
  mapname=$( __decode_mapname "${mapname}" )
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset value="$( \grep "^ENTRY:${mapname}${key}=" "${filename}" )"
  value="$( __decode_mapitem "${value}" )"

  [ -n "${value}" ] && printf "%s\n" "${value}"
  return "${PASS}"
}

hadd_entry_via_file()
{
  __debug $@

  typeset filename=
  typeset key=
  typeset value=
  typeset append="${NO}"
  typeset mapn='temp_map'
  
  OPTIND=1
  while getoptex "f: filename: k: key: v: value: m: mapname: append" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'    ) filename="${OPTARG}";;
    'k'|'key'         ) key="${OPTARG}";;
    'v'|'value'       ) value="${OPTARG}";;
        'append'      ) append="${YES}";;
    'm'|'mapname'     ) mapn="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ]
  then
    return "${FAIL}"
  else
    [ ! -f "${filename}" ] && \touch "${filename}"
  fi

  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset mapname="$( \grep "^KEYS" "${filename}" )"
  mapname=$( __decode_mapname "${mapname}" )
  if [ -z "${mapname}" ]
  then
    mapname="${mapn}"
    #printf "%s\n" "KEYS:${mapname}keys=\"${keys}\"" | \cat - "${filename}" > "${filename}.tmp"
    #\mv -f "${filename}.tmp" "${filename}"
  fi    
  
  #start_timer HCHANGE
  #typeset line="$( \awk "/^ENTRY:${mapname}${key}=/{print}" "${filename}" )"
  typeset line="$( \grep "^ENTRY:${mapname}${key}=" "${filename}" )"
  typeset RC=$?
  #echo "AAAA ${line} -- ${RC} -- ${mapname} --- ${key} --- ${value} -- ${filename}" >> /tmp/.xyz
  #echo "Grep for pre-existing line --> $( end_timer HCHANGE )" >> /tmp/.xyz
  #start_timer HCHANGE
  if [ "${RC}" -ne 0 ] || [ -z "${line}" ]
  then
    printf "%s\n" "ENTRY:${mapname}${key}=\"${value}\"" >> "${filename}"
    typeset keys="$( \grep "^KEYS" "${filename}" )"
    keys=$( __decode_mapitem "${keys}" )
    if [ -z "${keys}" ]
    then
      keys="${key}"
      printf "%s\n" "KEYS:${mapname}keys=\"${keys}\"" | \cat - "${filename}" > "${filename}.tmp"
      \mv -f "${filename}.tmp" "${filename}"
    else
      keys="$( __encode_mapitem "${keys} ${key}" )"
      \sed '1d' "${filename}" > "${filename}.tmp"
      printf "%s\n" "KEYS:${mapname}keys=\"${keys}\"" | \cat - "${filename}.tmp" > "${filename}"
      #\mv -f "${filename}.tmp" "${filename}"
    fi
    #printf "%s\n" "KEYS:${mapname}keys=\"${keys}\"" | \cat - "${filename}" > "${filename}.tmp"
    #\mv -f "${filename}.tmp" "${filename}"
    RC="${PASS}"
  else
    typeset extra_opts=
    [ "${append}" -eq "${NO}" ] && extra_opts='--replace'
    hchange_entry_via_file --filename "${filename}" --key "${key}" --value "${value}" ${extra_opts}
    RC=$?
  fi
  #echo "Writing/Replacing line in file --> $( end_timer HCHANGE )">> /tmp/.xyz
  return "${RC}" 
}

hadd_item()
{
  __debug $@
  
  typeset map=
  typeset key=
  typeset value=
  typeset unique="${NO}"
  
  OPTIND=1
  while getoptex "m: map: k: key: v: value: u unique" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'    ) map="${OPTARG}";;
    'k'|'key'    ) key="${OPTARG}";;
    'v'|'value'  ) value="${OPTARG}";;
    'u'|'unique' ) unique="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset val="$( hget --map "${map}" --key "${key}" )"

  if [ "$( is_empty --str "${val}" )" -eq "${YES}" ]
  then
    hassign --map "${map}" --key "${key}" --value "${value}"
    return $?
  fi
  
  typeset inv
  for inv in ${value}
  do

  ###
  ### Need to better handle uniqueness
  ###
  if [ "${unique}" -eq "${YES}" ]
  then
    #typeset OLDIFS="${IFS}"
    if [ -n "${inv}" ]
    then
      typeset v=
      typeset found="${NO}"
      #IFS="${__MAP_ITEM_SEPARATOR}"
      for v in ${val}
      do
        if [ "${v}" == "${inv}" ]
        then
          found="${YES}"
          break
        fi
      done
      #IFS="${OLDIFS}"
      if [ "${found}" -eq "${NO}" ]
      then
        val="${val}${__MAP_ITEM_SEPARATOR}${inv}"
        val=$( printf "%s\n" "${val}" | \tr -s ' ' )
      fi
    fi
  else
    val="${val}${__MAP_ITEM_SEPARATOR}${inv}"
  fi


  done

  hput --map "${map}" --key "${key}" --value "${val}"
  return $?
}

hassign()
{
  __debug $@

  typeset map=
  typeset key=
  typeset value=

  OPTIND=1
  while getoptex "m: map: k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    'v'|'value' ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && return "${FAIL}"
  
  hexport --map "${map}" --key "${key}" --value "${value}"
  return $?
}

hchange_entry_via_file()
{
  __debug $@

  typeset filename=
  typeset key=
  typeset value=
  typeset replace="${NO}"
  
  OPTIND=1
  while getoptex "f: filename: k: key: v: value: replace" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'    ) filename="${OPTARG}";;
    'k'|'key'         ) key="${OPTARG}";;
    'v'|'value'       ) value="${OPTARG}";;
        'replace'     ) replace="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] && return "${FAIL}"
  [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset mapname="$( \grep "^KEYS" "${filename}" )"
  mapname=$( __decode_mapname "${mapname}" )
  #typeset mapname="$( \grep "^KEYS" "${filename}" | \cut -f 1 -d '=' | \cut -f 2 -d ':' | \sed -e 's#keys$##' )" #\sed -e "s#^KEYS:\(\\w*\)keys=\"\(\\w*\)\"\$#\1#" )"
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset line="$( \grep "^ENTRY:${mapname}${key}=" "${filename}" )"
  \grep -v "^ENTRY:${mapname}${key}=" "${filename}" >> "${filename}.tmp"
  if [ -n "${line}" ]
  then
    typeset prefix="$( printf "%s\n" "${line}" | \cut -f 1 -d '=' )"
    if [ "${replace}" -eq "${YES}" ]
    then
      printf "%s\n" "${prefix}=\"${value}\"" >> "${filename}.tmp"
    else
      typeset oldvalue="$( printf "%s\n" "${line}" | \cut -f 2 -d '=' | \sed -e 's#^"##' -e 's#"$##' )"
      if [ "$( is_empty --str "${oldvalue}" )" -eq "${YES}" ]
      then
        printf "%s\n" "${prefix}=\"${value}\"" >> "${filename}.tmp"
      else
        printf "%s\n" "${prefix}=\"${oldvalue} ${value}\"" >> "${filename}.tmp"
      fi
    fi
  else
    printf "%s\n" "ENTRY:${mapname}${key}=\"${value}\"" >> "${filename}"
  fi
  \mv -f "${filename}.tmp" "${filename}"
  return "${PASS}" 
}

hclear()
{
  __debug $@
  
  typeset map=
  typeset key=

  OPTIND=1
  while getoptex "k: key: m: map:" "$@"
  do
    case "${OPTOPT}" in
    'k'|'key' ) key="${OPTARG}";;
    'm'|'map' ) map="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset allkeys
  typeset full_removal="${NO}"
  
  if [ "$( is_empty --str "${key}" )" -eq "${YES}" ]
  then
    allkeys="$( hkeys --map "${map}" )"
    full_removal="${YES}"
  else
    allkeys="${key}"
  fi

  typeset are_keys_exported="$( hget --map "${map}" --key "${__EXPORT_KEY}" )"
  typeset k=
  for k in ${allkeys}
  do
    [ "${k}" == "${__EXPORT_KEY}" ] && continue
    
    __debug "Deleting key ( ${k} )"
    
    hunassign --map "${map}" --key "${k}"
  done
  
  if [ "${full_removal}" -eq "${YES}" ]
  then
    __debug "Deleting map ( ${map} )"

    hunassign --map "${map}" --key 'keys'
    hunassign --map "${map}" --key "${__EXPORT_KEY}"
    
    unset "${map}"
  fi
  
  return "${PASS}"
}

hcontains_entry_via_file()
{
  __debug $@
  
  typeset filename=
  typeset key=
  typeset match=
  
  OPTIND=1
  while getoptex "f: filename: k: key: match:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'   ) filename="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
        'match'      ) match="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ]
  then
    print_no
    return "${FAIL}"
  fi
  if [ "$( is_empty --str "${key}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  if [ "$( is_empty --str "${match}" )" -eq "${YES}" ]
  then
    print_no
    return "${NO}"
  fi

  typeset mapname="$( \grep "^KEYS" "${filename}" )"
  mapname=$( __decode_mapname "${mapname}" )
  #typeset mapname="$( \grep "^KEYS" "${filename}" | \cut -f 1 -d '=' | \cut -f 2 -d ':' | \sed -e 's#keys$##' )" #\sed -e "s#^KEYS:\(\\w*\)keys=\"\(\\w*\)\"\$#\1#" )"
  [ -z "${mapname}" ] && return "${FAIL}"

  \grep "^ENTRY:${mapname}${key}" "${filename}" | \grep -q "${match}"
  typeset RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${RC}"
}

hcontains()
{
  __debug $@
  
  typeset map=
  typeset key=
  typeset match=
  
  OPTIND=1
  while getoptex "m: map: k: key: match:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
        'match' ) match="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${match}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  typeset data="$( hget --map "${map}" --key "${key}" )"
  if [ -z "${data}" ]
  then
    print_no
    return "${PASS}"
  else
    typeset data_match="$( printf "%s\n" ${data} | \awk "/(^| )${match}( |$)/" )"
    RC=$?
    if [ -n "${data_match}" ]
    then
      print_yes
    else
      print_no
    fi
    return "${RC}"
  fi
}

hcount()
{
  __debug $@
  
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    'k'|'key' ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"
  
  if [ -z "${key}" ]
  then
    typeset keys="$( hkeys --map "${map}" )"
    typeset count="$( __get_word_count "${keys}" )"

    printf "%d\n" "${count}"
  else
    typeset data="$( hget --map "${map}" --key "${key}" )"
    if [ -n "${data}" ]
    then
      printf "%d\n" "$( __get_word_count --non-file "${data}" )"
    else
      printf "%d\n" 0
    fi
  fi
  
  return "${PASS}"
}

hdec()
{
  __debug $@
  
  typeset decr=1
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key: d: decr:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'  ) map="${OPTARG}";;
    'k'|'key'  ) key="${OPTARG}";;
    'd'|'decr' ) decr="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset value="$( hget --map "${map}" --key "${key}" )"
  if [ "$( is_empty --str "${value}" )" -eq "${YES}" ]
  then
    value="${decr}"
  else
    value="$( decrement "${value}" "${decr}" )"
  fi
  
  hput --map "${map}" --key "${key}" --value "${value}"
  return $?
}

hdel_item()
{
  __debug $@
  
  typeset RC="${PASS}"
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    'v'|'value' ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset val="$( hget --map "${map}" --key "${key}" | \sed -e "s#${__MAP_ITEM_SEPARATOR}# #g" )"

  [ "$( is_empty --str "${val}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset v=
  typeset newval=
  for v in ${val}
  do
    if [ "x${v}" == "x${value}" ]
    then
      continue
    else
      if [ -z "${newval}" ]
      then
	      newval="${v}"
      else
	      newval="${newval}${__MAP_ITEM_SEPARATOR}${v}"
      fi
    fi
  done
  
  val="${newval}"
  if [ ${#val} -eq 0 ]
  then
    hunassign --map "${map}" --key "${key}"
    return $?
  fi
  
  hput --map "${map}" --key "${key}" --value "${val}"
  return $?
}

hdel()
{
  __debug $@
  
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    'k'|'key' ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset varname="$( __get_key_name "${map}" "${key}" )"
  
  eval "${varname}="
  unset "${varname}"
  
  typeset keys=$( hkeys --map "${map}" )
  typeset final=
  typeset k=
  for k in ${keys}
  do
    [ "x${k}" == "x${key}" ] && continue
    if [ "$( is_empty --str "${final}" )" -eq "${YES}" ]
    then
      final="${k}"
    else
      final="${final}${__KEY_SEPARATOR}${k}"
    fi
  done
  
  eval "${map}""keys"="${final}"

  return "${PASS}"
}

henable_global()
{
  __debug $@
  
  typeset map=
  typeset key=

  OPTIND=1
  while getoptex "m: map:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"
  
  hassign --map "${map}" --key "${__EXPORT_KEY}" --value "${YES}"
  return $?
}

hexists()
{
  __debug $@
  
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    'k'|'key' ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  typeset result="$( hget --map "${map}" --key "${key}" )"
  if [ "$( is_empty --str "${result}" )" -eq "${NO}" ]
  then
    print_yes
  else
    print_no
  fi
}

hexists_map()
{
  __debug $@
  
  typeset map=
  
  OPTIND=1
  while getoptex "m: map:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${map}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  typeset varname="$( __get_key_name "${map}" 'keys' )"
  eval "result=${varname}"
  
  if [ -n "${result}" ]
  then
    print_yes
  else
    print_no
  fi 
}

hexport()
{
  __debug $@
  
  typeset map=
  typeset value=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: v: value: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    'v'|'value' ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${value}")" -eq "${YES}" ] && return "${FAIL}"
  
  hput --map "${map}" --key "${key}" --value "${value}"
  
  typeset found_export_key="$( hexists --map "${map}" --key "${__EXPORT_KEY}" )"

  if [ "${found_export_key}" -eq "${YES}" ]
  then
    typeset should_export="$( hget --map "${map}" --key "${__EXPORT_KEY}" )"
    if [ -n "${should_export}" ] && [ "${should_export}" -eq "${YES}" ]
    then
      typeset varname="$( __get_key_name "${map}" "${key}" )"
      export "${varname}"
    fi
  fi
  
  return "${PASS}"
}

hget()
{
  __debug $@
  
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    'k'|'key' ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  typeset varname="$( __get_key_name "${map}" "${key}" )"
  
  eval echo '${'"${varname}"'#${map}}' | \tr "${__MAP_ITEM_SEPARATOR}" ' ' | \sed -e "s#${__VALUE_ITEM_SEPARATOR}# #g"
  return "${PASS}"
}

hget_mapname()
{
  __debug $@
  
  typeset filename=
  
  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  typeset allkeysline="$( \grep '^KEYS:' "${filename}" )"
  
  [ "$( is_empty --str "${allkeysline}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset known_keys="$( printf "%s\n" "${allkeysline}" | \cut -f 2 -d '=' )"
  typeset mapname="$( printf "%s\n" "${allkeysline}" )"
  mapname=$( __decode_mapname "${mapname}" )
  #typeset mapname="$( printf "%s\n" "${allkeysline}" | \cut -f 1 -d '=' | \sed -e 's#^KEYS:##' -e 's#keys$##' -e "s#${__VALUE_ITEM_SEPARATOR}# #g" )"
  
  [ -n "${mapname}" ] && printf "%s\n" "${mapname}"
  return "${PASS}"
}

hinc()
{
  __debug $@
  
  typeset incr=1
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key: i: incr:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'  ) map="${OPTARG}";;
    'k'|'key'  ) key="${OPTARG}";;
    'i'|'incr' ) incr="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset value="$( hget --map "${map}" --key "${key}" )"
  if [ "$( is_empty --str "${value}" )" -eq "${YES}" ]
  then
    value="${incr}"
  else
    value="$( increment "${value}" "${incr}" )"
  fi
  
  hput --map "${map}" --key "${key}" --value "${value}"
  return $?
}

hkeys()
{
  __debug $@
  
  typeset map=
  typeset no_modify=${YES}
  
  OPTIND=1
  while getoptex "m: map: n. non-modify." "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'        ) map="${OPTARG}";;
    'n'|'non-modify' ) no_modify=${NO};;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset result="$( hget --map "${map}" --key keys )"
  [ "${no_modify}" -eq "${YES}" ] && result="$( printf "%s\n" "${result}" | \sed -e "s#${__KEY_SEPARATOR}# #g" )"
  print_plain --message "${result}"
  return "${PASS}"
}

hpersist()
{
  __debug $@

  typeset map=
  typeset filename=
  typeset clobber="${NO}"
  typeset rename="${NO}"
  typeset new_map_name=
  
  OPTIND=1
  while getoptex "m: map: f: filename: c clobber r: rename:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'      ) map="${OPTARG}";;
    'f'|'filename' ) filename="${OPTARG}";;
    'c'|'clobber'  ) clobber="${YES}";;
    'r'|'rename'   ) rename="${YES}"; new_map_name="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
 
  [ "${rename}" -eq "${YES}" ] && [ "$( is_empty --str "${new_map_name}" )" -eq "${YES}" ] && rename="${NO}"

  [ -f "${filename}" ] && [ "${clobber}" -eq "${NO}" ] && return "${FAIL}"
  
  typeset allkeys="$( hkeys --map "${map}" )"
  [ "$( is_empty --str "${allkeys}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset reduced_allkeys="$( printf "%s\n" "${allkeys}" | \sed -e "s#[ $( printf '\t' )]#${__VALUE_ITEM_SEPARATOR}#g" )"
  if [ "${rename}" -eq "${YES}" ]
  then
    print_plain --msg "KEYS:${new_map_name}keys=\"${reduced_allkeys}\"" > "${filename}"
  else
    print_plain --msg "KEYS:${map}keys=\"${reduced_allkeys}\"" > "${filename}"
  fi
  
  typeset k=
  for k in ${allkeys}
  do
    typeset v="$( hget --map "${map}" --key "${k}" | \sed -e "s#[ $( printf '\t' )]#${__VALUE_ITEM_SEPARATOR}#g" )"
    if [ "${rename}" -eq "${YES}" ]
    then
      print_plain --msg "ENTRY:${new_map_name}${k}=\"${v}\"" >> "${filename}"
    else
      print_plain --msg "ENTRY:${map}${k}=\"${v}\"" >> "${filename}"
    fi
  done
  return "${PASS}"
}

hprint()
{
  __debug $@

  typeset map=
  
  OPTIND=1
  while getoptex "m: map:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map' ) map="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"
 
  typeset keys=
  if [ $# -gt 0 ]
  then
    keys="$*"
  else
    keys=$( hkeys --map "${map}" )
  fi
  print_plain --message "Map : ${map}"
  typeset k=
  for k in ${keys}
  do
    __debug "Checking key : ${k}"
    [ -z "${k}" ] || [ "${k}" == 'keys' ] || [ "${k}" == "${__EXPORT_KEY}" ] && continue
    
    typeset val="$( hget --map "${map}" --key "${k}" )"
    if [ -n "${val}" ]
    then
      typeset modkey="$( printf "%s\n" "${val}" | \sed -e "s#${__MAP_ITEM_SEPARATOR}# #g" )"
      print_plain --message "   Key ( ${k} ) has value ( ${modkey} )"
    else
      print_plain --message "   Key ( ${k} ) does NOT have any associated value(s)"
    fi
  done
  return "${PASS}"
}

hput()
{
  __debug $@
  
  typeset map=
  typeset key=
  typeset value=
  
  OPTIND=1
  while getoptex "m: map: k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'v'|'value' ) value="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset numwords="$( __get_word_count "${value}" )"
  typeset varname="$( __get_key_name "${map}" "${key}" )"

  if [ "${numwords}" -ge 2 ]
  then
    value="$( printf "%s\n" "${value}" | \tr ' ' "${__MAP_ITEM_SEPARATOR}" )"
  fi
  eval "${varname}=\"${value}\""

  typeset ck="$( hkeys --map "${map}" --non-modify )"
  typeset ck_modify="$( hkeys --map "${map}" )"

  typeset k=
  for k in ${ck_modify}
  do
    [ -z "${k}" ] && continue
    [ "${k}" == "${key}" ] && return "${PASS}"
  done
  
  if [ "$( is_empty --str "${ck}" )" -eq "${YES}" ]
  then
    ck="${key}"
  else
    ck="${ck}${__KEY_SEPARATOR}${key}"
  fi
  
  eval "${map}""keys"="${ck}"

  if [ "${key}" == "${__EXPORT_KEY}" ]
  then
    typeset varname="$( __get_key_name "${map}" "${key}" )"
    export "${varname}"
    varname="$( __get_key_name "${map}" keys )"
    export "${varname}"
  fi
  
  return "${PASS}"
}

hread_map()
{
  __debug $@

  typeset filename=
  typeset mapname=
  typeset clobber="${NO}"
  typeset getmapname="${NO}"
  
  OPTIND=1
  while getoptex "f: filename: c clobber m: map: getmapname" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'    ) filename="${OPTARG}";;
    'c'|'clobber'     ) clobber="${YES}";;
    'm'|'map'         ) mapname="${OPTARG}";;
        'getmapname'  ) getmapname="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  
  [ ! -f "${filename}" ] && return "${FAIL}"
  
  typeset allkeysline="$( \grep '^KEYS:' "${filename}" )"
  
  [ "$( is_empty --str "${allkeysline}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset known_keys="$( printf "%s\n" "${allkeysline}" | \cut -f 2 -d '=' )"
  typeset map="$( printf "%s\n" "${allkeysline}" )"
  map="$( __decode_mapname "${map}" )"
  
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] && return "${FAIL}"

  [ -z "${mapname}" ] && mapname="${map}"
  
  eval "${mapname}="
  [ "$( is_empty --str "${known_keys}" )" -eq "${YES}" ] && return "${PASS}"

  ###
  ### Need to ensure the export enablement feature is done first so that
  ###   interpretation of all remaining keys properly exports them as needed
  ###
  printf "%s\n" "${known_keys}" | \grep -q "${__EXPORT_KEY}"
  [ $? -eq "${PASS}" ] && hassign --map "${mapname}" --key "${__EXPORT_KEY}" --value "${YES}"
    
  typeset keylines=$( \grep '^ENTRY:' "${filename}" | \grep "${map}" )
  typeset l=
  for l in ${keylines}
  do
    typeset k="$( printf "%s\n" "${l}" | \cut -f 1 -d '=' | \sed -e "s#^ENTRY:${map}##" -e "s#${__VALUE_ITEM_SEPARATOR}# #g" )"
    [ "${k}" == "${__EXPORT_KEY}" ] && continue
    
    typeset v="$( printf "%s\n" "${l}" | \cut -f 2 -d '=' )"
    hassign --map "${mapname}" --key "${k}" --value "${v}"
  done

  [ "${clobber}" -eq "${YES}" ] && \rm -f "${filename}"
  [ "${getmapname}" -eq "${YES}" ] && printf "%s\n" "${mapname}"
  return "${PASS}"
}

hreverse_map()
{
  __debug $@
  
  typeset oldmap=
  typeset newmap=
  
  OPTIND=1
  while getoptex "o: old-map: n: new-map:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'old-map' ) oldmap="${OPTARG}";;
    'n'|'new-map' ) newmap="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${oldmap}" )" -eq "${YES}" ] || [ "$( is_empty --str "${newmap}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset keys="$( hkeys --map "${oldmap}" )"
  typeset key=
  for key in ${keys}
  do    
    typeset newmapkey="$( hget --map "${oldmap}" --key "${key}" )"
    if [ -n "${__ALLOW_MULTIMAP}" ] && [ "${__ALLOW_MULTIMAP}" -eq 1 ]
    then
      typeset content="$( hget --map "${newmap}" --key "${newmapkey}" )"
      [ -n "${content}" ] && key="${key}${__KEY_SEPARATOR}${content}"
    fi
    hassign --map "${newmap}" --key "${newmapkey}" --value "${key}"
  done
  return "${PASS}"
}

hunassign()
{
  __debug $@

  typeset map=
  typeset key=

  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  hunexport --map "${map}" --key "${key}"  
  return $?
}

hunexport()
{
  __debug $@
  
  typeset RC="${PASS}"
  typeset map=
  typeset key=
  
  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"
    
  hdel --map "${map}" --key "${key}"
  RC=$?
  
  if [ "$( hcontains --map "${map}" --key "${__EXPORT_KEY}" --match "${key}" )" -eq "${YES}" ]
  then
    typeset should_export="$( hget --map "${map}" --key "${key}" )"
    if [ -n "${should_export}" ] && [ "${should_export}" -eq "${YES}" ]
    then
      typeset varname="$( __get_key_name "${map}" "${key}" )"  
      export -n "${varname}"
    fi
  fi
  
  return "${RC}"
}

huniquify()
{
  __debug $@

  typeset RC="${PASS}"
  typeset map=
  typeset key=

  OPTIND=1
  while getoptex "m: map: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset data="$( hget --map "${map}" --key "${key}" )"
  data="$( printf "%s\n" ${data} | \awk '!uniq[$0]++' )"
  hput --map "${map}" --key "${key}" --value "${data}"
  RC=$?

  if [ "$( hcontains --map "${map}" --key "${__EXPORT_KEY}" --match "${key}" )" -eq "${YES}" ]
  then
    typeset should_export="$( hget --map "${map}" --key "${key}" )"
    if [ -n "${should_export}" ] && [ "${should_export}" -eq "${YES}" ]
    then
      typeset varname="$( __get_key_name "${map}" "${key}" )"
      export -n "${varname}"
    fi
  fi

  return "${RC}"
}

hupdate()
{
  __debug $@
  
  typeset map=
  typeset key=
  typeset value=
  
  OPTIND=1
  while getoptex "m: map: k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'   ) map="${OPTARG}";;
    'k'|'key'   ) key="${OPTARG}";;
    'v'|'value' ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))    

  [ "$( is_empty --str "${map}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] || [ "$( is_empty --str "${value}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset data="$( hget --map "${map}" --key "${key}" )"
  if [ -z "${data}" ]
  then
    hassign --map "${map}" --key "${key}" --value "${value}"
    return $?
  fi

  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/base_logging.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/numerics.sh"
fi

__initialize_hashmaps
__prepared_hashmaps
