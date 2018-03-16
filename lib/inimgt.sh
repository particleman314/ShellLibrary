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
## @Software Package : Shell Automated Testing -- INI File Parsing
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.54
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __disable_ini_failure
#    __enable_ini_failure
#    __find_substitution
#    __get_key_from_section
#    __get_section_from_file
#    __get_section_from_file_by_lineno
#    __ini_suppression
#    ini_copy_key
#    ini_copy_section
#    ini_fail
#    ini_get_channel
#    ini_get_file
#    ini_get_key_from_section
#    ini_get_keys
#    ini_get_section
#    ini_get_sections
#    ini_merge_keys
#    ini_merge_sections
#    ini_remove_key
#    ini_remove_section
#    ini_rename_key
#    ini_rename_section
#    ini_set_file
#    ini_set_output_file
#    ini_set_output_channel
#    ini_update_key
#    ini_unset_file
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2210,SC2206,SC2086,SC1001

__disable_ini_failure()
{
  typeset setting="${1:-${YES}}"

  if [ -z "${__INI_FAILURE_SUPPRESSION}" ]
  then
    __INI_FAILURE_SUPPRESSION="${YES}"
  else
    __INI_FAILURE_SUPPRESSION="$(( __INI_FAILURE_SUPPRESSION + setting ))"
  fi

  __INI_FAILURE_SUPPRESSION="$( __range_limit "${__INI_FAILURE_SUPPRESSION}" "${NO}" "${YES}" )"
}

__enable_ini_failure()
{
  __INI_FAILURE_SUPPRESSION="${NO}"
}

__find_substitution()
{
  typeset leftside="$1"
  typeset rightside="$2"
  typeset input="$3"

  typeset RC="${PASS}"
  
  [ -z "${leftside}" ] || [ -z "${rightside}" ] && return "${FAIL}"
  [ -z "${input}" ] && return "${FAIL}"

  typeset leftlen=${#leftside}
  typeset rightlen=${#rightside}
  
  typeset left=$( strindex "${input}" "${leftside}" )
  
  typeset match=
  if [ "${left}" -ne -1 ]
  then
    typeset right=$( strindex "${input}" "${rightside}" )
    if [ "${right}" -ne -1 ]
    then
      left=$(( left + ${leftlen} - 1 ))
      typeset diff=$(( right - left - rightlen ))
      match="${input:${left}:${diff}}"
    else
      RC="${FAIL}"
    fi
  else
    RC="${FAIL}"
  fi
  
  [ -n "${match}" ] && printf "%s\n" "${match}"
  return "${RC}"
}

__find_key_line_limits()
{
  __debug $@

  typeset RC="${PASS}"
  typeset filename="$1"
  typeset section="$2"
  typeset key="$3"

  if [ -z "${filename}" ] || [ ! -f "${filename}" ] || [ -z "${section}" ] || [ -z "${key}"]
  then
    printf "%s\n" '-1:-1'
    return "${FAIL}"
  fi

  typeset lineid="$( __find_line_for_key "${filename}" "${section}" "${key}" )"
  RC=$?
  if [ "${lineid}" -lt 0 ] || [ "${RC}" -ne "${PASS}" ]
  then
    printf "%s\n" '-1:-1'
    return "${FAIL}"
  fi

  typeset maxlines=$( __get_line_count "${filename}" )
  typeset startorig="${lineid}"

  while [ "${lineid}" -le "${maxlines}" ]
  do
    typeset line="$( trim "$( copy_file_segment --filename "${filename}" --beginline "${lineid}" --endline "${lineid}" )" )"
    typeset commentline="$( __remove_ini_comments "${line}" )"
    echo "${lineid} +++ ${line} +++ [ ${commentline} ]" >> /tmp/.xyz
    if [ $( is_empty --str "${commentline}" ) -ne "${YES}" ]
    then
      typeset lastchar="${line:$((${#commentline}-1)):1}"
      if [ "${lastchar}" != '\' ]  
      then
        printf "%s\n" "${startorig}:${lineid}"
        return "${PASS}"
      fi
    fi
    lineid=$( increment "${lineid}" )
  done

  printf "%s\n" "${startorig}:${maxlines}"
  return "${PASS}"
}

__find_line_for_key()
{
  typeset filename="$1"
  typeset section="$2"
  typeset key="$3"

  if [ -z "${filename}" ] || [ ! -f "${filename}" ] || [ -z "${section}" ] || [ -z "${key}"]
  then
    printf "%d\n" '-1'
    return "${FAIL}"
  fi

  typeset matched_section_line="$( __find_line_for_section "${filename}" "${section}" )"
  if [ "${matched_section_line}" -lt 0 ]
  then
    printf "%d\n" '-1'
    return "${FAIL}"
  fi

  typeset matched_key_lines="$( \sed -e 's#^[[:space:]]*##' "${filename}" | \grep -n "^${key}" | \cut -f 1 -d ':' | \tr '\n' ' ' )"
  typeset mkl=
  typeset found="${NO}"
  for mkl in ${matched_key_lines}
  do
    if [ "${mkl}" -gt "${matched_section_line}" ]
    then
      found="${YES}"
      break
    fi
  done

  if [ "${found}" -eq "${YES}" ]
  then
    printf "%d\n" "${mkl}"
  else
    printf "%d\n" '-1'
    return "${FAIL}"
  fi

  return "${PASS}"
}

__find_line_for_section()
{
  typeset RC="${PASS}"
  typeset filename="$1"
  typeset section="$2"

  if [ -z "${filename}" ] || [ ! -f "${filename}" ] || [ -z "${section}" ]
  then
    printf "%d\n" '-1'
    return "${FAIL}"
  fi

  typeset match="$( \grep -n "^\[${section}\]" "${filename}" | \head -n 1 | \cut -f 1 -d ':' )"
  if [ -z "${match}" ]
  then
    printf "%d\n" '-1'
    RC="${FAIL}"
  else
    printf "%d\n" "${match}"
  fi
  return "${RC}"
}

__find_section_line_limits()
{
  typeset RC="${PASS}"
  typeset filename="$1"
  typeset section="$2"

  typeset bl="$( __find_line_for_section "${filename}" "${section}" )"
  RC=$?

  if [ "${RC}" -ne "${PASS}" ] || [ "${bl}" -lt 0 ]
  then
    printf "%s\n" '-1:-1'
    return "${FAIL}"
  fi

  ### Find emptyline or non consecutive section line following matching section line
  ### TODO -- need to handle the "reused" sections methodology
  typeset endline="$( \grep -n '^$' "${filename}" | \cut -f 1 -d ':' )"
  number_matches="$( __get_line_count --non-file "${endline}" )"
  if [ ${number_matches} -lt 1 ]
  then
    printf "%s\n" '-1:-1'
    return "${FAIL}"
  fi

  typeset el=
  typeset found="${NO}"
  for el in ${endline}
  do
    if [ "${el}" -gt "${bl}" ]
    then
      found="${YES}"
      break
    fi
  done
  if [ "${found}" -eq "${NO}" ]
  then
    el=$( __get_line_count "${filename}" | \cut -f 1 -d ' ' )
  else
    el=$(( el - 1 ))
  fi
  printf "%s\n" "${bl}:${el}"
  return "${RC}"
}

__get_key_from_section()
{
  typeset filename="$1"
  typeset section="$2"
  typeset key="$3"

  typeset RC="${PASS}"

  ### Check to see if the section exists
  typeset bgedlines="$( __find_section_line_limits "${filename}" "${section}" )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] || [ -z "${key}" ] && return "${FAIL}"

  typeset bgline="$( get_element --data "${bgedlines}" --id 1 --separator ':' )"
  typeset edline="$( get_element --data "${bgedlines}" --id 2 --separator ':' )"

  ### Look for the matching key requested
  typeset matched_entry="$( \sed -e "${bgline},${edline}p" "${filename}" | \sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*=[[:space:]]*/=/' | \grep "^${key}=" | \cut -f 2- -d '=' | \sed -e "s/^\([\"']\)\(.*\)\1\$/\2/g" )"
  [ -z "${matched_entry}" ] && return "${FAIL}"

  ### Access the value associated to the requested key and allow substitution
  while [ "${YES}" == "${YES}" ]
  do
    typeset subst="$( __find_substitution '${' '}' "${matched_entry}" )"
    if [ -z "${subst}" ]
    then
      value="${matched_entry}"
      break
    fi
    typeset structure="$( printf "%s\n" "${subst}" | \sed -e 's/:/\n/' | \wc -l )"
    typeset result=
    if [ "${structure}" -eq 1 ]
    then
      eval "result=\${${subst}}"
    else
      typeset newsection="$( printf "%s\n" "${subst}" | \cut -f 1 -d ':' )"
      typeset newkey="$( printf "%s\n" "${subst}" | \cut -f 2 -d ':' )"
      result="$( __get_key_from_section "${filename}" "${newsection}" "${newkey}" )"
      [ $? -ne "${PASS}" ] && break
    fi
    matched_entry="$( printf "%s\n" "${matched_entry}" | \sed -e "s#\${${subst}}#${result}#g" )"
  done

  ### Double check that quotation marks are removed...
  typeset value="$( printf "%s\n" "${value}" | \sed -e "s/^\([\"']\)\(.*\)\1\$/\2/g" )"

  [ -n "${value}" ] && printf "%s\n" "${value}"
  return "${PASS}"
}

__get_section_from_file()
{
  typeset filename="$1"
  typeset section="$2"

  ### Check inputs
  [ ! -f "${filename}" ] && return "${FAIL}"
  [ -z "${section}" ] && return "${FAIL}"

  typeset bgedlines="$( __find_actual_section_limits "${filename}" "${section}" )"
  typeset bgline="$( get_element --data "${bgedlines}" --id 1 --separator ':' )"
  typeset edline="$( get_element --data "${bgedlines}" --id 2 --separator ':' )"

  [ "${bgline}" -eq -1 ] || [ "${edline}" -eq -1 ] && return "${FAIL}"
  copy_file_segment --filename "${filename}" --beginline "${bgline}" --endline "${edline}p"
  return $?
}

__get_section_from_file_by_lineno()
{
  typeset RC="${PASS}"

  typeset filename="$1"
  typeset section="$2"

  ### Check inputs
  [ ! -f "${filename}" ] && return "${FAIL}"
  [ -z "${section}" ] && return "${FAIL}"

  ### Identify output file with comments removed
  typeset output_ini_file="$( get_temp_dir )/.$( \basename "${filename}" ).stripped"
  typeset result='0:0'

  if [ ! -f "${output_ini_file}.${section}.extracted" ]
  then
    __get_section_from_file "${filename}" "${section}" > /dev/null
    RC=$?
  fi

  if [ "${RC}" -eq "${PASS}" ]
  then
    result="$( \tail -n 1 "${output_ini_file}.${section}.extracted" | \sed -e 's/###\s*//' )"
    if [ -n "${result}" ]
    then
      printf "%s\n" "${result}"
    else
      printf "%s\n" '0:0'
    fi
  else
    printf "%s\n" "${result}"
  fi
  return "${RC}"
}

__initialize_inimgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  # shellcheck source=/dev/null
  __load __initialize_stringmgt "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
  # shellcheck source=/dev/null
  __load __initialize_data_structures "${SLCF_SHELL_TOP}/lib/data_structures.sh"

  [ -z "${__STD_INIFILE}" ] && __STD_INIFILE=
  
  __INI_TRACING_CHANNEL='INI'
  __INI_TRACING_FILE=

  __enable_ini_failure
  __initialize "__initialize_inimgt"
}

__ini_suppression()
{
  typeset msg="$1"

  [ "$( is_empty --str "${msg}" )" -eq "${YES}" ] && return "${PASS}"

  if [ "${__INI_FAILURE_SUPPRESSION}" -eq "${NO}" ]
  then
    print_plain --message "[ ERROR ] ${msg}"
    append_output --channel 'ERROR' --data "${msg}"
  elif [ "${__INI_FAILURE_SUPPRESSION}" -eq "${YES}" ]
  then
    append_output --channel 'ERROR' --data "${msg}"
  fi

  return "${PASS}"
}

__prepared_inimgt()
{
  __prepared "__prepared_inimgt"
}

__remove_ini_comments()
{
  __debug $@

  typeset data="$1"
  printf "%s\n" "${data}" | \sed '/[[:space:]]*[;#]/ d' -f "${SLCF_SHELL_TOP}/resources/common/.c_ctyle_comments.sed"
  return "${PASS}"
}

ini_add_key()
{
  __debug $@

  typeset RC="${PASS}"

  typeset inifile=
  typeset section=
  typeset key=
  typeset value=

  OPTIND=1
  while getoptex "i. inifile. s: section: k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value'        ) value="${OPTARG}";;
    'i'|'inifile'      ) inifile="${OPTARG}";;
        'section'      ) section="${OPTARG}";;
        'key'          ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"
  [ -z "${key}" ] && return "${FAIL}"

  typeset tmpfile="$( make_output_file )"

  ### Check to see if the section exists
  typeset endline=
  typeset sectionlineid="$( __find_actual_line_for_section "${inifile}" "${section}" )"
  RC=$?

  if [ "${RC}" -eq "${PASS}" ] && [ "${sectionlineid}" -ge 0 ]
  then
    typeset bgs=$( increment ${sectionlineid} )

    \sed "${bgs}i\   ${key} = ${value}" "${inifile}" >> "${tmpfile}"
    [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${inifile}"

  else
    ini_add_section --inifile "${inifile}" --section "${section}"
    printf "%s\n" "   ${key} = ${value}" >> "${inifile}"
  fi

  remove_output_file --filename "${tmpfile}"
  return "${PASS}"
}

ini_add_section()
{
  __debug $@

  typeset RC="${PASS}"

  typeset inifile=
  typeset section=

  OPTIND=1
  while getoptex "i. inifile. section:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'inifile'      ) inifile="${OPTARG}";;
        'section'      ) section="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  typeset tmpfile="$( make_output_file )"

  typeset sectionlineid="$( __find_actual_line_for_section "${inifile}" "${section}" )"
  RC=$?

  ### Did not find the section name requested
  if [ "${RC}" -ne "${PASS}" ] || [ "${sectionlineid}" -lt 0 ]
  then
    \sed '$ {/^$/d;}' "${inifile}" > "${tmpfile}"
    printf "\n%s\n" "[${section}]" >> "${tmpfile}"
    [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${inifile}"
  fi

  remove_output_file --filename "${tmpfile}"
  return "${PASS}"
}

ini_copy_key()
{
  __debug $@

  typeset RC="${PASS}"
  typeset inifile=
  typeset oldsection=
  typeset oldkey=
  typeset newsection=
  typeset newkey=
  
  OPTIND=1
  while getoptex "oldsection: i. inifile. oldkey: newsection: newkey:" "$@"
  do
    case "${OPTOPT}" in
        'oldsection'   ) oldsection="${OPTARG}";;
    'i'|'inifile'      ) inifile="${OPTARG}";;
        'oldkey'       ) oldkey="${OPTARG}";;
        'newsection'   ) newsection="${OPTARG}";;
        'newkey'       ) newkey="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${oldsection}" ] && return "${FAIL}"
  [ -z "${oldkey}" ] && return "${FAIL}"

  [ -z "${newsection}" ] && newsection="${oldsection}"
  if [ -z "${newkey}" ]
  then
    [ "${oldsection}" == "${newsection}" ] && return "${FAIL}"
    newkey="${oldkey}"
  else
    [ "${oldkey}" == "${newkey}" ] && [ "${oldsection}" == "${newsection}" ] && return "${FAIL}"
  fi

  typeset bgedkeylines=$( __find_actual_key_limits "${inifile}" "${section}" "${oldkey}" )
  typeset bgkline=$( get_element --data "${bgedkeylines}" --id 1 --separator ':' )
  typeset edkline=$( get_element --data "${bgedkeylines}" --id 2 --separator ':' )

  [ "${bgkline}" -lt 0 ] || [ "${edkline}" -lt 0 ] && return "${FAIL}"

  typeset tmpfile="$( make_output_file )"
  typeset content="$( copy_file_segment --filename "${inifile}" --beginline "${bgkline}" --endline "${edkline}" )"

  typeset newsectline=$( __find_actual_line_for_section "${inifile}" "${newsection}" )
  if [ "${newsectline}" -lt 0 ]
  then
    ini_add_section --inifile "${inifile}" --section "${newsection}"
    RC=$?

    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
    newsectline=$( __find_actual_line_for_section "${inifile}" "${newsection}" )
  fi

  newsectline=$( increment "${newsectline}" )

  \sed -e "${newsectline}i${content}" "${inifile}" >> "${tmpfile}"
  RC=$?

  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${inifile}"
  remove_output_file --filename "${tmpfile}"
  return "${RC}"
}

ini_copy_section()
{
  __debug $@

  typeset inifile=
  typeset oldsection=
  typeset newsection=
  
  OPTIND=1
  while getoptex "oldsection: i. inifile. newsection:" "$@"
  do
    case "${OPTOPT}" in
        'oldsection'   ) oldsection="${OPTARG}";;
    'i'|'inifile'      ) inifile="${OPTARG}";;
        'newsection'   ) newsection="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${oldsection}" ] && return "${FAIL}"
  [ -z "${newsection}" ] && return "${FAIL}"

  [ "${oldsection}" == "${newsection}" ] && return "${FAIL}"

  typeset beg_end_lines="$( __find_actual_section_limits "${inifile}" "${oldsection}" )"
  typeset bgln=$( get_element --data "${beg_end_lines}" --id 1 --separator ':' )
  typeset edln=$( get_element --data "${beg_end_lines}" --id 2 --separator ':' )

  [ "${bgln}" -eq -1 ] || [ "${edln}" -eq -1 ] && return "${FAIL}"

  typeset tmpfile="$( make_output_file )"
  typeset content="$( copy_file_segment --filename "${inifile}" --beginline "${bgln}" --endline "${edln}" )"
  RC=$?

  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  printf "\n%s\n" "${content}" >> "${inifile}"
  
  typeset copied_section_marker="$( \grep -n "^\[${oldsection}\]" "${inifile}" | \tail -n 1 | \cut -f 1 -d ':' )"

  \sed "${copied_section_marker}s/${oldsection}/${newsection}/" "${inifile}" > "${tmpfile}"
  [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${inifile}"

  return "${PASS}"
}

ini_fail()
{
  __debug $@

  typeset msg=
  typeset errorcode="${FAIL}"
  
  OPTIND=1
  while getoptex "m: msg: message: e: errorcode:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'errorcode'     ) errorcode="${OPTARG}";;
    'm'|'msg'|'message' ) msg="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${msg}" )" -eq "${NO}" ] && __ini_suppression "${msg}"

  return "${errorcode}"
}

ini_get_channel()
{
  __debug $@
  printf "%s\n" "${__INI_TRACING_CHANNEL}"
  return "${PASS}"
}

ini_get_file()
{
  [ -n "${__STD_INIFILE}" ] && print_plain --message "${__STD_INIFILE}"
  return "${PASS}"
}

ini_get_key()
{
  __debug $@

  typeset inifile=
  typeset section=
  typeset key=
  
  OPTIND=1
  while getoptex "s: section: i. inifile. k: key:" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    'k'|'key'       ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  ### Needs to handle multi-line input setting???
  __get_key_from_section "${inifile}" "${section}" "${key}"
  return $?
}

ini_get_keys()
{
  __debug $@

  typeset inifile=
  typeset section=
  
  OPTIND=1
  while getoptex "s: section: i. inifile." "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  typeset subinifile="$( __get_section_from_file "${inifile}" "${section}" )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"
  [ "$( is_empty --str "${subinifile}" )" -eq "${YES}"} ] || [ ! -f "${subinifile}" ] && return "${FAIL}"

  ### Need to clean section content before requesting keys
  typeset bgendlines=$( __find_actual_section_limits "${inifile}" "${section}" )
  typeset bgline="$( get_element --data "${bgendlines}" --id 1 --separator ':' )"
  typeset edline="$( get_element --data "${bgendlines}" --id 2 --separator ':' )"
  [ "${bgline}" -eq -1 ] || [ "${edline}" -eq -1 ] && return "${FAIL}"

  bgline=$( increment "${bgline}" )

  typeset content="$( copy_file_segment --filename "${inifile}" --beginline "${bgline}" --endline "${edline}" )"
  RC=$?

  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  content="$( __remove_ini_comments "${content}" )"
  typeset section_keys="$( \sed -e 's#[[:space:]]*\(.*\)[[:space:]]*=[[:space:]]*\(.*\)#\1#' | \tr '\n' ' ' )"
  [ -n "${section_keys}" ] && printf "%s\n" "${section_keys}"

  return "${PASS}"
}

ini_get_section()
{
  __debug $@

  typeset inifile=
  typeset section=

  OPTIND=1
  while getoptex "s: section: i. inifile." "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  typeset bgendlines=$( __find_actual_section_limits "${inifile}" "${section}" )

  typeset bgline="$( get_element --data "${bgendlines}" --id 1 --separator ':' )"
  typeset edline="$( get_element --data "${bgendlines}" --id 2 --separator ':' )"
  [ "${bgline}" -eq -1 ] || [ "${edline}" -eq -1 ] && return "${FAIL}"
  
  copy_file_segment --filename "${inifile}" --beginline "${bgline}" --endline "${edline}"
  return $?
}

ini_get_sections()
{
  __debug $@

  typeset inifile=
  
  OPTIND=1
  while getoptex "i. inifile." "$@"
  do
    case "${OPTOPT}" in
    'i'|'inifile'   ) inifile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset known_sections="$( \grep '^\[' "${inifile}" | \sed -e 's#\[\(.*\)\]#\1#' | \tr '\n' ' ' )"
  [ -n "${known_sections}" ] && printf "%s\n" "${known_sections}"
  return "${PASS}"
}

ini_has_key()
{
  __debug $@

  typeset inifile=
  typeset section=
  typeset key=
  
  OPTIND=1
  while getoptex "s: section: i. inifile. k: key:" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    'k'|'key'       ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  typeset result="$( ini_get_key --inifile "${inifile}" --section "${section}" --key "${key}" )"
  if [ "$( is_empty --str "${result}" )" -eq "${YES}" ]
  then
    print_no
  else
    print_yes
  fi
  return "${PASS}"  
}

ini_merge_keys()
{
  __debug $@

  typeset RC="${PASS}"

  typeset inifile=
  typeset oldsection=
  typeset newsection=
  typeset placement='NEW'

  OPTIND=1
  while getoptex "oldsection: i. inifile. newsection: placement:" "$@"
  do
    case "${OPTOPT}" in
        'oldsection'   ) oldsection="${OPTARG}";;
    'i'|'inifile'      ) inifile="${OPTARG}";;
        'newsection'   ) newsection="${OPTARG}";;
        'placement'    ) placement=$( to_upper "${OPTARG}" );;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${oldsection}" ] && return "${FAIL}"
  [ -z "${newsection}" ] && return "${FAIL}"

  [ "${oldsection}" == "${newsection}" ] && return "${FAIL}"

  [ "${placement}" != 'NEW' ] && [ "${placement}" != 'OLD' ] && placement='NEW'

  if [ "${placement}" == 'OLD' ]
  then
    keep_section="${oldsection}"
    rm_section="${newsection}"
  else
    keep_section="${newsection}"
    rm_section="${oldsection}"
  fi

  typeset keys_keep="$( ini_get_keys --inifile "${inifile}" --section "${keep_section}" )"
  typeset keys_rm="$( ini_get_keys --inifile "${inifile}" --section "${rm_section}" )"

  if [ -z "${keys_rm}" ]
  then
    ###
    ### No keys in removal section to copy to new section -- Nothing to do
    return "${PASS}"
  else
    if [ -z "${keys_keep}" ]
    then
      ###
      ### New section is just a header without any keys, then just rename the section...
      ###
      ini_rename_section --inifile "${inifile}" --old-section "${rm_section}" --new-section "${keep_section}"
      return $?
    else
      ###
      ### Copy keys from the removal section to the new section taking care to merge the contents of keys
      ###    where necessary
      ###
      list_add --object 'keeplist' --data "${keys_keep}"
      list_add --object 'rmlist' --data "${keys_rm}"

      typeset keys_in_common=$( intersection "$( list_data --object 'keeplist' )" "$( list_data --object 'rmlist' )" )
      typeset keys_disparate="$( ini_get_keys --inifile "${inifile}" --section "${rm_section}" )"

      typeset kd=
      for kd in $( list_data --object "${keys_disparate}" )
      do
        typeset final_value="$( ini_get_key --inifile "${inifile}" --section "${rm_section}" --key "${kd}" )"
        if [ "$( list_has --object "${keys_disparate}" --data "${kd}" )" -eq "${YES}" ]
        then
          typeset valuenew="$( ini_get_key --inifile "${inifile}" --section "${keep_section}" --key "${kd}" )"
          final_value="$( trim "${final_value} ${value_new}" )"

          ini_remove_key --inifile "${inifile}" --section "${keep_section}" --key "${kd}"
        fi
        ini_add_key --inifile "${inifile}" --section "${keep_section}" --key "${kd}" --value "${final_value}"
      done
    fi
  fi

  ini_remove_section --inifile "${inifile}" --section "${rm_section}"
  return $?
}

ini_merge_sections()
{
  __debug $@
}

ini_remove_key_from_section()
{
  __debug $@

  typeset inifile=
  typeset section=
  typeset key=
  typeset return_content="${NO}"
  typeset overwrite="${NO}"
  typeset RC="${PASS}"

  OPTIND=1
  while getoptex "s: section: i. inifile. k: key: c content overwrite" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    'k'|'key'       ) key="${OPTARG}";;
    'c'|'content'   ) return_content="${YES}";;
        'overwrite' ) overwrite="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ "$( is_empty --str "${section}" )" -eq "${YES}" ] || [ "$( is_empty --str "${key}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset lineno="$( __find_actual_line_for_key "${inifile}" "${section}" "${key}" )"
  [ "${lineno}" -le 0 ] && return "${PASS}"

  typeset tmpfile="$( make_output_file )"
  \sed -e "${lineno}d" "${inifile}" >> "${tmpfile}"
  RC=$?

  if [ "${overwrite}" -eq "${YES}" ]
  then
   \mv -f "${tmpfile}" "${inifile}"
    remove_output_file --filename "${tmpfile}"
    tmpfile="${inifile}"
  fi

  if [ "${return_content}" -eq "${YES}" ]
  then
    \cat "${tmpfile}"
  else
    printf "%s\n" "${tmpfile}"
  fi
  return "${RC}"
}

ini_remove_section()
{
  __debug $@

  typeset RC="${PASS}"
  typeset inifile=
  typeset section=
  typeset return_content="${NO}"
  typeset overwrite="${NO}"
  
  OPTIND=1
  while getoptex "s: section: i. inifile. c content overwrite" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'   ) section="${OPTARG}";;
    'i'|'inifile'   ) inifile="${OPTARG}";;
    'c'|'content'   ) return_content="${YES}";;
        'overwrite' ) overwrite="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"

  typeset bgend="$( __find_actual_section_limits "${inifile}" "${section}" )"

  typeset begline=$( get_element --data "${bgend}" --id 1 --separator ':' )
  typeset endline=$( get_element --data "${bgend}" --id 2 --separator ':' )

  [ "${begline}" -eq '-1' ] || [ "${endline}" -eq '-1' ] && return "${FAIL}"

  endline=$(( endline + 1 ))

  typeset tmpfile="$( make_output_file )"
  \sed "${begline},${endline}d" "${inifile}" >> "${tmpfile}"
  RC=$?

  if [ "${overwrite}" -eq "${YES}" ]
  then
    \mv -f "${tmpfile}" "${inifile}"
    remove_output_file --filename "${tmpfile}"
    tmpfile="${inifile}"
  fi

  if [ "${return_content}" -eq "${YES}" ]
  then
    \cat "${tmpfile}"
  else
    printf "%s\n" "${tmpfile}"
  fi
  return "${RC}"
}

ini_rename_key()
{
  __debug $@

  typeset RC="${PASS}"
  typeset inifile=
  typeset oldsection=
  typeset oldkey=
  typeset newkey=
  typeset return_content="${NO}"
  typeset overwrite="${NO}"

  OPTIND=1
  while getoptex "s: section: i. inifile. a: old-key: b:new-key c content overwrite" "$@"
  do
    case "${OPTOPT}" in
    's'|'section'       ) section="${OPTARG}";;
    'a'|'old-key'       ) oldkey="${OPTARG}";;
    'b'|'new-key'       ) newkey="${OPTARG}";;
    'i'|'inifile'       ) inifile="${OPTARG}";;
    'c'|'content'       ) return_content="${YES}";;
        'overwrite'     ) overwrite="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${section}" ] && return "${FAIL}"
  [ -z "${oldkey}" ] || [ -z "${newkey}" ] && return "${FAIL}"
  [ "${oldkey}" == "${newkey}" ] && return "${FAIL}"

  typeset opts=
  [ "${overwrite}" -eq "${YES}"} ] && opts+=' --overwrite'
  [ "${return_content}" -eq "${YES}" ] && opts+=' --content'

  typeset newfile="$( ini_copy_key --inifile "${inifile}" --old-section "${section}" --old-key "${oldkey}" --new-key "${newkey}" )"
  RC=$?
  [ "${RC}" -eq "${FAIL}" ] && return "${FAIL}"

  typeset result="$( ini_remove_key_from_section --inifile "${newfile}" --old-section "${section}" --key "${oldkey}" ${opts} )"
  printf "%s\n" "${result}"
  return "${RC}"
}

ini_rename_section()
{
  __debug $@

  typeset RC="${PASS}"
  typeset inifile=
  typeset oldsection=
  typeset newsection=
  typeset return_content="${NO}"
  typeset overwrite="${NO}"

  OPTIND=1
  while getoptex "a: old-section: i. inifile. b: new-section: c content overwrite" "$@"
  do
    case "${OPTOPT}" in
    'a'|'old-section'   ) old_section="${OPTARG}";;
    'b'|'new-section'   ) new_section="${OPTARG}";;
    'i'|'inifile'       ) inifile="${OPTARG}";;
    'c'|'content'       ) return_content="${YES}";;
        'overwrite'     ) overwrite="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && inifile="${__STD_INIFILE}"
  [ "$( is_empty --str "${inifile}" )" -eq "${YES}" ] && return "${FAIL}"

  ### Check inputs
  [ -z "${old_section}" ] && return "${FAIL}"
  [ -z "${new_section}" ] && return "${FAIL}"

  typeset new_section_content="$( __find_actual_line_for_section "${inifile}" "${old_section}" )"
  [ $? -eq 0 ] || [ -n "${new_section_content}" ] && ini_remove_section --inifile "${inifile}" --section "${new_section}"

  typeset changeline="$( \grep -n "^\[${old_section}\]" | \head -n 1 | \cut -f 1 -d ':' )"
  typeset tmpfile="$( make_output_file )"
  \sed -e "${changeline}s/${old_section}/${new_section}" "${inifile}" > "${tmpfile}"
  RC=$?

  if [ "${overwrite}" -eq "${YES}" ]
  then
   \mv -f "${tmpfile}" "${inifile}"
    remove_output_file --filename "${tmpfile}"
    tmpfile="${inifile}"
  fi

  if [ "${return_content}" -eq "${YES}" ]
  then
    \cat "${tmpfile}"
  else
    printf "%s\n" "${tmpfile}"
  fi
  return "${PASS}"
}

ini_set_file()
{
  __debug $@
  typeset inifile=
  typeset ignore="${NO}"

  OPTIND=1
  while getoptex "i: inifile: ignore-existence" "$@"
  do
    case "${OPTOPT}" in
    'i'|'inifile'          ) inifile="${OPTARG}";;
        'ignore-existence' ) ignore="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "${ignore}" -eq "${NO}" ]
  then
    [ "$( is_empty --str "${inifile}" )" -eq "${NO}" ] && [ -f "${inifile}" ] && __STD_INIFILE="${inifile}"
    return "${PASS}"
  else
    __STD_INIFILE="${inifile}"
  fi

  return "${FAIL}"
}

ini_set_output_file()
{
  __debug $@

  typeset iniout=

  OPTIND=1
  while getoptex "i: iniout:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'iniout' ) iniout="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  __INI_TRACING_FILE="${iniout}"
  associate_file_to_channel --channel "${__INI_TRACING_CHANNEL}" --file "${__INI_TRACING_FILE}" --ignore-file-existence --persist
  return $?
}

ini_set_output_channel()
{
  __debug $@

  typeset inichannel=

  OPTIND=1
  while getoptex "i: inichannel:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'inichannel' ) inichannel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${inichannel}" ] && return "${FAIL}"
  __INI_TRACING_CHANNEL="${inichannel}"
  return "${PASS}"
}

ini_update_key()
{
  __debug $@
}

ini_unset_file()
{
  __STD_INIFILE=
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then

  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/stringmgt.sh"

   # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/data_structures.sh"
 
fi

__initialize_inimgt
__prepared_inimgt
