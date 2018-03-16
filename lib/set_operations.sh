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
## @Software Package : Shell Automated Testing -- Set Operations
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.01
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __improper_set
#    __make_list_files
#    complement
#    intersection
#    remove_duplicates
#    symmetric_difference
#    union
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2181,SC2086

__initialize_set_operations()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )
    
  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  
  __initialize "__initialize_set_operations"
}

__prepared_set_operations()
{
  __prepared "__prepared_set_options"
}

__improper_set()
{
  typeset set1=
  typeset set2=
  typeset not_as_file="${NO}"
  
  OPTIND=1
  while getoptex "s1: s2: non-file" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    's2'        ) set2="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${set1}" ] || [ -z "${set2}" ]
  then
    if [ -z "${set1}" ]
    then
      if [ "${not_as_file}" -eq "${YES}" ]
      then
        printf "%s\n" "${set2}"
      else
        \cat "${set2}"
      fi
    else
      if [ "${not_as_file}" -eq "${YES}" ]
      then
        printf "%s\n" "${set1}"
      else
        \cat "${set1}"
      fi
    fi
    return "${FAIL}"
  fi
  
  return "${PASS}"
}

__make_list_files()
{
  typeset set1=
  typeset set2=
  
  OPTIND=1
  while getoptex "s1: s2:" "$@"
  do
    case "${OPTOPT}" in
    's1'  ) set1="${OPTARG}";;
    's2'  ) set2="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset uniqdate="$( \date "+%s" )"
  printf "%s\n" ${set1} > "/tmp/$$.${uniqdate}"
  set1="/tmp/$$.${uniqdate}"
    
  sleep_func -s 1 --old-version
    
  uniqdate="$( \date "+%s" )"
  printf "%s\n" ${set2} > "/tmp/$$.${uniqdate}"
  set2="/tmp/$$.${uniqdate}"

  printf "%s\n" "${set1}|${set2}"
  return "${PASS}"
}

complement()
{
  typeset set1
  typeset set2
  typeset not_as_file="${NO}"
  
  OPTIND=1
  while getoptex "s1: s2: non-file" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    's2'        ) set2="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset output=
  typeset RC="${PASS}"
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" --non-file )"
    RC=$?
  else
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" )"
    RC=$?
  fi
  
  if [ "${RC}" -eq "${FAIL}" ]
  then
    printf "%s\n" "${output}"
    return "${PASS}"
  fi
    
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    typeset result="$( __make_list_files --s1 "${set1}" --s2 "${set2}" )"
    set1="$( get_element --data "${result}" --id 1 --separator '|' )"
    set2="$( get_element --data "${result}" --id 2 --separator '|' )"
  fi
  
  \sort "${set2}" "${set2}" "${set1}" | \uniq -u 
  [ "${not_as_file}" -eq "${YES}" ] && \rm -f "${set1}" "${set2}"
  
  return "${PASS}"
}

intersection()
{
  typeset set1=
  typeset set2=
  typeset not_as_file="${NO}"
  typeset use_regex="${NO}"
  
  OPTIND=1
  while getoptex "s1: s2: non-file regex" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    's2'        ) set2="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    'regex'     ) use_regex="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset output=
  typeset RC="${PASS}"
  
  if [ "${use_regex}" -eq "${NO}" ]
  then
    if [ "${not_as_file}" -eq "${YES}" ]
    then
      output="$( __improper_set --s1 "${set1}" --s2 "${set2}" --non-file )"
      RC=$?
    else
      output="$( __improper_set --s1 "${set1}" --s2 "${set2}" )"
      RC=$?
    fi
  
    if [ "${RC}" -eq "${FAIL}" ]
    then
      printf "%s\n" "${output}"
      return "${PASS}"
    fi
    
    if [ "${not_as_file}" -eq "${YES}" ]
    then
      typeset result="$( __make_list_files --s1 "${set1}" --s2 "${set2}" )"
      set1="$( get_element --data "${result}" --id 1 --separator '|' )"
      set2="$( get_element --data "${result}" --id 2 --separator '|' )"
    fi

    \sort "${set1}" "${set2}" | \uniq -d
    [ "${not_as_file}" -eq "${YES}" ] && \rm -f "${set1}" "${set2}"
  else
    typeset matched_output=
    if [ "${not_as_file}" -eq "${YES}" ]
    then
      output="$( __improper_set --s1 "${set1}" --non-file )"
    else
      output="$( __improper_set --s1 "${set1}" )"
    fi
    
    typeset looper=
    for looper in ${set2}
    do
      matched_output+=" $( printf "%s\n" ${output} | \grep "${looper}" )"
    done
    printf "%s\n" "${matched_output}"
  fi
  
  return "${PASS}"
}

remove_duplicates()
{
  typeset set1=
  typeset not_as_file="${NO}"
  
  OPTIND=1
  while getoptex "s1: non-file" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset output=
  typeset RC="${PASS}"
  
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    output="$( __improper_set --s1 "${set1}" --non-file )"
    RC=$?
  fi
  if [ "${RC}" -eq "${FAIL}" ]
  then
    printf "%s\n" "${set1}"
    return "${PASS}"
  fi
    
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    typeset result="$( __make_list_files --s1 "${set1}" )"
    set1="$( get_element --data "${result}" --id 1 --separator '|' )"
  fi
  
  printf "%s\n" ${set1} | \awk '!a[$0]++'
  [ "${not_as_file}" -eq "${YES}" ] && \rm -f "${set1}"

  return "${PASS}"
}

symmetric_difference()
{
  typeset set1=
  typeset set2=
  typeset not_as_file="${NO}"
  
  OPTIND=1
  while getoptex "s1: s2: non-file" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    's2'        ) set2="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset output=
  typeset RC="${PASS}"
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" --non-file )"
    RC=$?
  else
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" )"
    RC=$?
  fi
  
  if [ "${RC}" -eq "${FAIL}" ]
  then
    printf "%s\n" "${output}"
    return "${PASS}"
  fi
    
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    typeset result="$( __make_list_files --s1 "${set1}" --s2 "${set2}" )"
    set1="$( get_element --data "${result}" --id 1 --separator '|' )"
    set2="$( get_element --data "${result}" --id 2 --separator '|' )"
  fi
  
  \sort "${set1}" "${set2}" | \uniq -u 
  [ "${not_as_file}" -eq "${YES}" ] && \rm -f "${set1}" "${set2}"
  
  return "${PASS}"
}

union()
{
  typeset set1=
  typeset set2=
  typeset not_as_file="${NO}"
  
  OPTIND=1
  while getoptex "s1: s2: non-file" "$@"
  do
    case "${OPTOPT}" in
    's1'        ) set1="${OPTARG}";;
    's2'        ) set2="${OPTARG}";;
    'non-file'  ) not_as_file="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset output=
  typeset RC="${PASS}"
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" --non-file )"
    RC=$?
  else
    output="$( __improper_set --s1 "${set1}" --s2 "${set2}" )"
    RC=$?
  fi
  
  if [ "${RC}" -eq "${FAIL}" ]
  then
    printf "%s\n" "${output}"
    return "${PASS}"
  fi
    
  if [ "${not_as_file}" -eq "${YES}" ]
  then
    typeset result="$( __make_list_files --s1 "${set1}" --s2 "${set2}" )"
    set1="$( get_element --data "${result}" --id 1 --separator '|' )"
    set2="$( get_element --data "${result}" --id 2 --separator '|' )"
  fi

  \sort -u "${set1}" "${set2}"
  [ "${not_as_file}" -eq "${YES}" ] && \rm -f "${set1}" "${set2}"
  
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
fi

__initialize_set_operations
__prepared_set_operations
