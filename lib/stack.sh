#!/bin/sh
###############################################################################
# Copyright (c) 2017.  All rights reserved. 
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
# Software Package : Shell Automated Testing -- Stack Management
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_last_stack_result
#    __stack_remove_element
#    stack_clear
#    stack_find
#    stack_has
#    stack_peek
#    stack_pop
#    stack_print
#    stack_push
#    stack_size
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2068,SC2039,SC2086,SC2181

[ -z "${__stack_element_name}" ] && __stack_element_name='stack'

__get_last_stack_result()
{
  [ -z "${__stack_result}" ] && return "${PASS}"
  printf "%s\n" "${__stack_result}"
  __stack_result=
  return "${PASS}"
}

__initialize_stack()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_list "${SLCF_SHELL_TOP}/lib/list.sh"

  __initialize "__initialize_stack"
}

__prepared_stack()
{
  __prepared "__prepared_stack"
}

__stack_remove_element()
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
  
  typeset data="$( stack_data --object "${mapname}" )"
  typeset number_entries="$( __get_word_count --non-file "${data}" )"

  if [ "${number_entries}" -eq 1 ]
  then
    __stack_result="${data}"
    stack_clear --object "${mapname}" --key "${__stack_element_name}"
  else
    __stack_result="$( printf "%s\n" "${data}" | \cut -f 1 -d ' ' )"
    data="$( printf "%s\n" ${data} | sed '1d' | tr '\n' ' ' )"
    hput --map "${mapname}" --key "${__stack_element_name}" --value "${data}"
  fi
  return $?
}

stack_clear()
{
  __debug $@
  
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

stack_data()
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

  hget --map "${mapname}" --key "${__stack_element_name}"
  return $?
}

stack_find()
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
  
  typeset data="$( stack_data --object "${mapname}" )"
  typeset result="$( printf "%s\n" ${data} | \grep -n "^${match}\b" )"
  typeset idx=
  
  [ -n "${result}" ] && idx="$( printf "%s\n" ${result} | \head -n 1 | \cut -f 1 -d ':' )"
  [ -n "${idx}" ] && printf "%d\n" "${idx}"
  return "${PASS}"
}

stack_has()
{
  __debug $@
  
  list_has $@ --key "${__stack_element_name}"
  return $?
}

stack_peek()
{
  __debug $@
  
  typeset mapname=
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'    ) mapname="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset data="$( hget --map "${mapname}" --key "${__stack_element_name}" )"
  [ -z "${data}" ] && return "${FAIL}"
  
  typeset result="$( get_element --data "${data}" --id 1 --separator ' ' )"
  __stack_result="${result}"

  return "${PASS}"
}

stack_pop()
{
  __debug $@

  typeset RC="${PASS}"
  
  typeset mapname=
  
  OPTIND=1
  while getoptex "o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'    ) mapname="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset data="$( hget --map "${mapname}" --key "${__stack_element_name}" )"
  [ -z "${data}" ] && return "${FAIL}"
  
  typeset result="$( get_element --data "${data}" --id 1 --separator ' ' )"
  __stack_result="${result}"
  __stack_remove_element --object "${mapname}"
  
  return $?
}

stack_print()
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
  printf "%s\n" "Stack : $( stack_data --object "${mapname}" )"
  return $?
}

stack_push()
{
  __debug $@
  
  typeset RC="${PASS}"
  typeset mapname=
  typeset input=
  typeset unique="${NO}"
  
  OPTIND=1
  while getoptex "o: object: d: data: u unique" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'     ) mapname="${OPTARG}";;
    'd'|'data'       ) input="${OPTARG}";;
    'u'|'unique'     ) unique="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${input}" ] && return "${FAIL}"

  typeset other_opts=
  [ "${unique}" -eq "${YES}" ] && other_opts=' --unique'

  if [ "${unique}" -eq "${YES}" ]
  then
    typeset result="$( hcontains --map "${mapname}" --key "${__stack_element_name}" --match "${input}" )"
    [ "${result}" -eq "${YES}" ] && return "${FAIL}"
  fi
  
  typeset data="$( hget --map "${mapname}" --key "${__stack_element_name}" )"
  typeset concatdata="${input} ${data}"
  hput --map "${mapname}" --key "${__stack_element_name}" --value "${concatdata}" ${other_opts}
  RC=$?

  return "${RC}"
}

stack_size()
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
  
  typeset data="$( stack_data --object "${mapname}" )"
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

__initialize_stack
__prepared_stack
