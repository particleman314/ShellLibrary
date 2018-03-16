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
## @Software Package : Shell Automated Testing -- Queue Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.02
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_last_queue_index
#    __get_last_queue_result
#    __get_priority_level
#    __queue_remove_element
#    __set_priority_level
#    queue_add
#    queue_clear
#    queue_delete
#    queue_find
#    queue_get_associated_priority
#    queue_has
#    queue_offer
#    queue_peek
#    queue_print
#    queue_size
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2068,SC2039,SC2086,SC2181

DEFAULT_PRIORITY_LEVEL=100
[ -z "${__queue_element_name}" ] && __queue_element_name='queue'

__get_last_queue_index()
{
  [ -z "${__queue_index}" ] && return "${PASS}"
  printf "%d\n" "${__queue_index}"
  __queue_index=
  return "${PASS}"
}

__get_last_queue_result()
{
  [ -z "${__queue_result}" ] && return "${PASS}"
  printf "%s\n" "${__queue_result}"
  __queue_result=
  return "${PASS}"
}

__get_priority_level()
{
  [ -z "${__priority_level}" ] && __priority_level="${DEFAULT_PRIORITY_LEVEL}"
  printf "%d\n" "${__priority_level}"
  return "${PASS}"
}

__initialize_queue()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_list "${SLCF_SHELL_TOP}/lib/list.sh"

  [ -z "${__priority_level}" ] && __priority_level=$( __get_priority_level )

  __initialize "__initialize_queue"
}

__prepared_queue()
{
  __prepared "__prepared_queue"
}

__queue_remove_element()
{
  __debug $@
  
  typeset mapname
  typeset idx=1

  OPTIND=1
  while getoptex "o: object: i: index:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'i'|'index'   ) idx="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${idx}" ] || [ "$( is_numeric_data --data "${idx}" )" -eq "${NO}" ] || [ "${idx}" -lt 1 ] && return "${FAIL}"
  
  typeset data="$( queue_data --object "${mapname}" )"
  typeset number_entries="$( __get_word_count --non-file "${data}" )"

  if [ "${idx}" -eq "${number_entries}" ] && [ "${idx}" -eq 1 ]
  then
    __queue_result="${data}"
    queue_clear --object "${mapname}" --key "${__queue_element_name}"
  else
    if [ "${idx}" -le "${number_entries}" ]
    then
      __queue_result="$( printf "%s\n" "${data}" | \awk -v i=1 -v j=${idx} 'FNR == i {print $j}' )"
      data="$( printf "%s\n" ${data} | \sed "${idx}d" | tr '\n' ' ' )"
      hput --map "${mapname}" --key "${__queue_element_name}" --value "${data}"

      typeset priorities="$( hget --map "${mapname}" --key 'priority' )"
      priorities="$( printf "%s\n" ${priorities} | \sed "${idx}d" | \tr '\n' ' ' )"

      hput --map "${mapname}" --key 'priority' --value "${priorities}"
    fi
  fi
  return "${PASS}"
}

__set_priority_level()
{
  typeset priority_level="$1"
  [ -z "${priority_level}" ] && __priority_level="${DEFAULT_PRIORITY_LEVEL}"
  [ "$( is_numeric_data --data "${priority_level}" )" -eq "${NO}" ] && return "${FAIL}"
  [ "${priority_level}" -lt 0 ] && return "${FAIL}"
  __priority_level="${priority_level}"
  return "${PASS}"
}

queue_add()
{
  __debug $@
  
  typeset RC="${PASS}"
  typeset mapname
  typeset input
  typeset priority
  typeset unique="${NO}"
  
  OPTIND=1
  while getoptex "o: object: d: data: p: priority: u unique" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'     ) mapname="${OPTARG}";;
    'd'|'data'       ) input="${OPTARG}";;
    'p'|'priority'   ) priority="${OPTARG}";;
    'u'|'unique'     ) unique="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${input}" ] && return "${FAIL}"
  
  typeset other_opts=
  [ "${unique}" -eq "${YES}" ] && other_opts=' --unique'

  if [ "${unique}" -eq "${YES}" ]
  then
    typeset result="$( hcontains --map "${mapname}" --key "${__queue_element_name}" --match "${input}" )"
    [ "${result}" -eq "${YES}" ] && return "${FAIL}"
  fi

  typeset number_distinct_inputs="$( __get_word_count --non-file "${input}" )"
  hadd_item --map "${mapname}" --key "${__queue_element_name}" --value "${input}" ${other_opts}
  RC=$?

  typeset count=0
  while [ "${count}" -lt "${number_distinct_inputs}" ]
  do
    if [ "${RC}" -eq "${PASS}" ]
    then
      if [ -z "${priority}" ]
      then
        hadd_item --map "${mapname}" --key 'priority' --value "$( __get_priority_level )"
        RC=$?
      else
        hadd_item --map "${mapname}" --key 'priority' --value "${priority}"
        RC=$?
      fi
    fi
    count=$(( count + 1 ))
  done

  return "${RC}"
}

queue_clear()
{
  __debug $@
  
  typeset mapname=
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  
  hclear --map "${mapname}"
  return "${PASS}"
}

queue_data()
{
  __debug $@

  typeset mapname=
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"

  hget --map "${mapname}" --key "${__queue_element_name}"
  return $?
}

queue_delete()
{
  __debug $@

  typeset mapname=
  typeset input=
  
  OPTIND=1
  while getoptex "o: object: d: data:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'd'|'data'    ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${input}" ] && return "${FAIL}"
  
  typeset data=
  typeset priority=
  
  typeset contains_item="$( hcontains --map "${mapname}" --key "${__queue_element_name}" --match "${input}" )"
  if [ "${contains_item}" -eq "${YES}" ]
  then
    data="$( hget --map "${mapname}" --key "${__queue_element_name}" )"
    priority="$( hget --map "${mapname}" --key 'priority' )"
    
    typeset number_entries="$( __get_word_count --non-file "${data}" )"
    
    typeset idx_match="$( printf "%s\n" ${data} | \grep -n "^${input}\b" | \cut -f 1 -d ':' )"
    [ -z "${idx_match}" ] && return "${PASS}"
    
    if [ "${idx_match}" -eq 1 ] && [ "${number_entries}" -eq 1 ]
    then
      queue_clear --object "${mapname}"
      return $?
    fi
    
    __queue_remove_element --object "${mapname}" --index "${idx_match}"
  fi
  return "${PASS}"
}

queue_find()
{
  __debug $@

  typeset mapname=
  typeset match=
  
  OPTIND=1
  while getoptex "o: object: m: match:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'm'|'match'   ) match="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${match}" ] && return "${FAIL}"
  
  typeset data="$( queue_data --object "${mapname}" )"
  typeset result="$( printf "%s\n" ${data} | \grep -n "^${match}\b" )"
  typeset idx=
  
  [ -n "${result}" ] && idx="$( printf "%s\n" ${result} | \head -n 1 | \cut -f 1 -d ':' )"
  [ -n "${idx}" ] && printf "%d\n" "${idx}"
  return "${PASS}"
}

queue_get_associated_priority()
{
  __debug $@

  typeset mapname=
  typeset match=

  OPTIND=1
  while getoptex "o: object: m: match:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'm'|'match'   ) match="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  if [ -z "${mapname}" ] || [ -z "${match}" ]
  then
    printf "%d\n" "$( __get_priority_level )"
    return "${FAIL}"
  fi
  
  typeset idx="$( queue_find --object "${mapname}" --match "${match}" )"
  typeset priorities="$( hget --map "${mapname}" --key 'priority' )"
  if [ -z "${priorities}" ]
  then
    printf "%d\n" "$( __get_priority_level )"
  else
    printf "%d\n" "$( get_element --data "${priorities}" --id "${idx}" --separator ' ' )"
  fi
  
  return "${PASS}"
}

queue_has()
{
  __debug $@
  
  list_has $@ --key "${__queue_element_name}"
  return $?
}

queue_peek()
{
  __debug $@
  
  typeset mapname=
  typeset priority=
  typeset highest_priority="${NO}"
  
  OPTIND=1
  while getoptex "o: object: p: priority: n next" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'    ) mapname="${OPTARG}";;
    'p'|'priority'  ) priority="${OPTARG}";;
    'n'|'next'      ) highest_priority="${YES}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  [ -n "${priority}" ] && highest_priority="${NO}"
  
  typeset data="$( hget --map "${mapname}" --key "${__queue_element_name}" )"
  [ -z "${data}" ] && return "${FAIL}"
  
  typeset stored_priority=
  typeset idx=1
  if [ -n "${priority}" ]
  then
    stored_priority="$( hget --map "${mapname}" --key 'priority' )"
    typeset output="$( printf "%d\n" ${stored_priority} | \grep -n "^${priority}\b" )"
    [ -n "${output}" ] && idx="$( printf "%s\n" ${output} | \head -n 1 | \cut -f 1 -d ':' )"
  fi

  if [ "${highest_priority}" -eq "${YES}" ]
  then
    stored_priority="$( hget --map "${mapname}" --key 'priority' )"
    typeset next_priority="$( printf "%s\n" ${stored_priority} | \sort -n | \head -n 1 )"
    queue_offer --object "${mapname}" --priority "${next_priority}"
    typeset RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __queue_index=
      return "${RC}"
    fi
    __queue_index="${next_priority}"
    return $?
  fi
  
  typeset result="$( get_element --data "${data}" --id "${idx}" --separator ' ' )"
  __queue_index="${idx}"
  __queue_result="${result}"

  return "${PASS}"
}

queue_offer()
{
  __debug $@

  typeset RC="${PASS}"
  
  typeset mapname=
  typeset priority=
  typeset highest_priority="${NO}"
  
  OPTIND=1
  while getoptex "o: object: p: priority: n next" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'    ) mapname="${OPTARG}";;
    'p'|'priority'  ) priority="${OPTARG}";;
    'n'|'next'      ) highest_priority="${YES}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  [ -n "${priority}" ] && highest_priority="${NO}"
  
  typeset data="$( hget --map "${mapname}" --key "${__queue_element_name}" )"
  [ -z "${data}" ] && return "${FAIL}"
  
  typeset stored_priority=
  typeset idx=1
  if [ -n "${priority}" ]
  then
    stored_priority="$( hget --map "${mapname}" --key 'priority' )"
    typeset output="$( printf "%d\n" ${stored_priority} | \grep -n "^${priority}\b" )"
    [ -n "${output}" ] && idx="$( printf "%s\n" ${output} | \head -n 1 | \cut -f 1 -d ':' )"
  fi

  if [ "${highest_priority}" -eq "${YES}" ]
  then
    stored_priority="$( hget --map "${mapname}" --key 'priority' )"
    typeset next_priority="$( printf "%s\n" ${stored_priority} | \sort -n | \head -n 1 )"
    queue_offer --object "${mapname}" --priority "${next_priority}"
    typeset RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __queue_index=
      return "${RC}"
    fi
    __queue_index="${next_priority}"
    return "${RC}"
  fi
  
  typeset result="$( get_element --data "${data}" --id "${idx}" --separator ' ' )"
  __queue_index="${idx}"
  __queue_result="${result}"

  __queue_remove_element --object "${mapname}" --index "${idx}"
  return $?
}

queue_print()
{
  __debug $@

  typeset mapname
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  printf "%s\n" "Queue : $( queue_data --object "${mapname}" )"
  return $?
}

queue_size()
{
  __debug $@

  typeset mapname
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset data="$( queue_data --object "${mapname}" )"
  typeset size="$( __get_word_count --non-file "${data}" )"
  printf "%d\n" "${size}"

  return $?
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/list.sh"
fi

__initialize_queue
__prepared_queue
