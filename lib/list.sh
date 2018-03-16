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
## @Software Package : Shell Automated Testing -- List Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.13
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_last_list_result
#    __list_remove_element
#    convert_to_list
#    list_add
#    list_clear
#    list_data
#    list_delete
#    list_find
#    list_get
#    list_has
#    list_intersection
#    list_print
#    list_size
#    list_symmetric_difference
#    list_unique
#    list_union
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2039,SC2068,SC2086,SC2181,SC2046

[ -z "${__list_element_name}" ] && __list_element_name='list'

__get_last_list_result()
{
  [ -z "${__list_result}" ] && return "${PASS}"
  printf "%s\n" "${__list_result}"
  __list_result=
  return "${PASS}"
}

__initialize_list()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"
  __load __initialize_hashmaps "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  __load __initialize_set_operations "${SLCF_SHELL_TOP}/lib/set_operations.sh"

  __initialize "__initialize_list"
}

__prepared_list()
{
  __prepared "__prepared_list"
}

__list_remove_element()
{
  __debug $@
  
  typeset mapname=
  typeset idx=
  typeset key="${__list_element_name}"
  
  OPTIND=1
  while getoptex "o: object: i: index: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'i'|'index'   ) idx="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  [ -z "${idx}" ] || [ "$( is_numeric_data --data "${idx}" )" -eq "${NO}" ] || [ "${idx}" -lt 1 ] && return "${FAIL}"
  
  typeset data="$( list_data --object "${mapname}" --key "${key}" )"
  typeset number_entries="$( list_size --object "${mapname}" )"
  
  if [ "${idx}" -eq "${number_entries}" ] && [ "${idx}" -eq 1 ]
  then
    __list_result="${data}"
    list_clear --object "${mapname}" --key "${key}"
  else
    if [ "${idx}" -le "${number_entries}" ]
    then
      __list_result="$( printf "%s\n" "${data}" | \awk -v i=1 -v j=${idx} 'FNR == i {print $j}' )"
      data="$( printf "%s\n" ${data} | \sed "${idx}d" | \tr '\n' ' ' )"
      hput --map "${mapname}" --key "${key}" --value "${data}"
    fi
  fi
  
  return "${PASS}"
}

convert_to_list()
{
  typeset RC="${PASS}"
  typeset mapname=
  typeset hmapname=
  typeset lkey="${__list_element_name}"
  typeset hkey=
  
  OPTIND=1
  while getoptex "o: object: lkey: m: hmap: hkey:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'     ) mapname="${OPTARG}";;
    'm'|'hmap'       ) hmapname="${OPTARG}";;
        'lkey'       ) lkey="${OPTARG}";;
        'hkey'       ) hkey="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${hmapname}" ] || [ -z "${hkey}" ] && return "${FAIL}"
  
  if [ "$( hexists --map "${hmapname}" --key "${hkey}" )" -eq "${YES}" ]
  then
    list_add --object "${mapname}" --data "$( hget --map "${hmapname}" --key "${hkey}" )"
    RC=$?
  else
    RC="${FAIL}"
  fi
  return "${RC}"
}

list_add()
{
  __debug $@
  
  typeset RC="${PASS}"
  typeset mapname=
  typeset input=
  typeset idx=-1
  typeset unique="${NO}"
  typeset key="${__list_element_name}"
  typeset in_front="${NO}"
  
  OPTIND=1
  while getoptex "o: object: d: data: i: index: u unique k: key: in-front" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'     ) mapname="${OPTARG}";;
    'd'|'data'       ) input="${OPTARG}";;
    'u'|'unique'     ) unique="${YES}";;
    'k'|'key'        ) key="${OPTARG}";;
    'i'|'index'      ) idx="${OPTARG}";;
        'in-front'   ) in_front="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${input}" ] && return "${FAIL}"
  
  typeset other_opts=
  [ "${unique}" -eq "${YES}" ] && other_opts=' --unique'

  if [ "${unique}" -eq "${YES}" ]
  then
    typeset result="$( hcontains --map "${mapname}" --key "${key}" --match "${input}" )"
    [ "${result}" -eq "${YES}" ] && return "${FAIL}"
  fi

  [ "${unique}" -eq "${YES}" ] && input="$( remove_duplicates --s1 "${input}" --not-as-file )"
  typeset data="$( list_data --object "${mapname}" --key "${key}" )"
  if [ "${in_front}" -eq "${YES}" ]
  then    
    data="${input} ${data}"
    hput --map "${mapname}" --key "${key}" --value "${data}"
    RC=$?
  else
    if [ "$( is_numeric_data --data "${idx}" )" -eq "${NO}" ] || [ "${idx}" -lt 1 ]
    then
      hadd_item --map "${mapname}" --key "${key}" --value "${input}" ${other_opts}
      RC=$?
    else
      typeset number_entries="$( list_size --object "${mapname}" --key "${key}" )"
      if [ "${number_entries}" -eq 0 ] || [ "${idx}" -ge "${number_entries}" ]
      then
        hadd_item --map "${mapname}" --key "${key}" --value "${input}" ${other_opts}
        RC=$?
      else
        if [ "${idx}" -eq 1 ]
        then
          data="${input} ${data}"
        else
          typeset data_before="$( printf "%s\n" "${data}" | \cut -f -$(( idx - 1 )) -d ' ' )"
          typeset data_after="$( printf "%s\n" "${data}" | \cut -f ${idx}- -d ' ' )"
          data="${data_before} ${input} ${data_after}"
        fi
        hput --map "${mapname}" --key "${key}" --value "${data}"
        RC=$?
      fi
    fi
  fi
  return "${RC}"
}

list_clear()
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

list_data()
{
  __debug $@

  typeset mapname=
  typeset key="${__list_element_name}"
  typeset separator=' '

  OPTIND=1
  while getoptex "o: object: k: key: s: separator:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'     ) mapname="${OPTARG}";;
    'k'|'key'        ) key="${OPTARG}";;
    's'|'separator'  ) separator="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"

  typeset data="$( hget --map "${mapname}" --key "${key}" )"
  [ "${separator}" != ' ' ] && data="$( printf "%s\n" "${data}" | \tr ' ' "${separator}" )"
  printf "%s\n" "${data}"
  return "${PASS}"
}

list_delete()
{
  __debug $@

  typeset mapname=
  typeset input=
  typeset index=
  typeset key="${__list_element_name}"
  
  OPTIND=1
  while getoptex "o: object: d: data: i: index: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'd'|'data'    ) input="${OPTARG}";;
    'i'|'index'   ) index="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  [ -z "${input}" ] && [ -z "${index}" ] && return "${FAIL}"
  [ -n "${input}" ] && [ -n "${index}" ] && return "${FAIL}"
  
  if [ -n "${input}" ]
  then
    typeset contains_item="$( hcontains --map "${mapname}" --key "${key}" --match "${input}" )"
    if [ "${contains_item}" -eq "${YES}" ]
    then
      typeset data="$( list_data --object "${mapname}" --key "${key}" )"
      typeset number_entries="$( list_size --object "${mapname}" --key "${key}" )"
    
      typeset idx_match="$( printf "%s\n" ${data} | \grep -n "^${input}\b" | \cut -f 1 -d ':' )"
      [ -z "${idx_match}" ] && return "${FAIL}"
    
      __list_remove_element --object "${mapname}" --index "${idx_match}"
      RC=$?
    fi
  else
    __list_remove_element --object "${mapname}" --index "${index}"
    RC=$?
  fi
  
  return "${RC}"
}

list_find()
{
  __debug $@

  typeset mapname=
  typeset match=
  typeset key="${__list_element_name}"
  typeset regex="${NO}"
  
  OPTIND=1
  while getoptex "o: object: m: match: k: key: r regex" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'm'|'match'   ) match="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
    'r'|'regex'   ) regex="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${match}" ] && return "${FAIL}"
  
  typeset data="$( list_data --object "${mapname}" --key "${key}" )"
  if [ "${regex}" -eq "${NO}" ]
  then
    grep_opts="^${match}\b"
  else
    grep_opts="${match}"
  fi
  typeset result="$( printf "%s\n" ${data} | \grep -n "${grep_opts}" )"
  typeset idx=
  
  [ -n "${result}" ] && idx="$( printf "%s\n" ${result} | \head -n 1 | \cut -f 1 -d ':' )"
  [ -n "${idx}" ] && printf "%d\n" "${idx}"
  
  return "${PASS}"
}

list_get()
{
  __debug $@  

  typeset mapname=
  typeset index=
  typeset key="${__list_element_name}"
  
  OPTIND=1
  while getoptex "o: object: i: index: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'i'|'index'   ) idx="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] | [ -z "${idx}" ] || [ "$( is_numeric_data --data "${idx}" )" -eq "${NO}" ] || [ "${idx}" -lt 0 ] && return "${FAIL}"
  
  typeset data="$( list_data --object "${mapname}" --key "${key}" )"
  get_element --data "${data}" --id "${idx}" --separator ' '
  return "${PASS}"
}

list_has()
{
  __debug $@
  
  typeset mapname
  typeset input
  typeset key="${__list_element_name}"
  
  OPTIND=1
  while getoptex "o: object: d: data: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'd'|'data'    ) input="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] || [ -z "${input}" ] && return "${FAIL}"
  
  typeset result="$( hcontains --map "${mapname}" --key "${key}" --match "${input}" )"
  printf "%d\n" "${result}"
  return "${PASS}"
}

list_intersect()
{
  __debug $@
  
  typeset list1
  typeset list2
  
  OPTIND=1
  while getoptex "list1: list2:" "$@"
  do
    case "${OPTOPT}" in
    'list1'  ) list1="${OPTARG}";;
    'list2'  ) list2="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${list1}" ] || [ -z "${list2}" ] && return "${FAIL}"
  
  intersection --s1 "$( list_data --object "${list1}" )" --s2 "$( list_data --object "${list2}" )" --non-file
  return $?  
}

list_print()
{
  __debug $@

  typeset mapname=
  typeset pretty_print="${NO}"

  OPTIND=1
  while getoptex "o: object: p pretty-print" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'        ) mapname="${OPTARG}";;
    'p'|'pretty-print'  ) pretty_print="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  if [ "${pretty_print}" -eq "${YES}" ]
  then
    printf "%s\n" "List : << ${mapname} >>"

    typeset num_entries="$( list_size --object "${mapname}" )"
    typeset maxdigits="$( number_digits "${num_entries}" )"

    typeset entry=
    for entry in $( list_data --object "${mapname}" )
    do
      printf "\t%${maxdigits}d) %s\n" "${entry}"
    done
  else
    printf "%s\n" "List : $( list_data --object "${mapname}" )"
  fi
  return "${PASS}"
}

list_size()
{
  __debug $@
  
  typeset mapname=
  typeset key="${__list_element_name}"
  
  OPTIND=1
  while getoptex "o: object: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'object'  ) mapname="${OPTARG}";;
    'k'|'key'     ) key="${OPTARG}";;
     esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${mapname}" ] && return "${FAIL}"
  
  typeset data="$( list_data --object "${mapname}" --key "${key}" )"
  typeset size="$( __get_word_count --non-file "${data}" )"
  printf "%d\n" "${size}"
  return "${PASS}"
}

list_symmetric_difference()
{
  __debug $@
  
  typeset list1
  typeset list2
  
  OPTIND=1
  while getoptex "list1: list2:" "$@"
  do
    case "${OPTOPT}" in
    'list1'  ) list1="${OPTARG}";;
    'list2'  ) list2="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${list1}" ] || [ -z "${list2}" ] && return "${FAIL}"
  
  symmetric_difference --s1 "$( list_data --object "${list1}" )" --s2 "$( list_data --object "${list2}" )" --non-file
  return $?
}

list_unique()
{
  __debug $@

  typeset RC=
  typeset list1

  OPTIND=1
  while getoptex "list1: o: object:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'list1'|'object'  ) list1="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${list1}" ] && return "${FAIL}"

  typeset result="$( trim "$( printf "%s\n" $( list_data --object "${list1}" ) | \sort | \uniq | \tr '\n' ' ' )" )"
  RC=$?
  printf "%s\n" "${result}"
  return "${RC}"
}

list_union()
{
  __debug $@
  
  typeset list1
  typeset list2
  
  OPTIND=1
  while getoptex "list1: list2:" "$@"
  do
    case "${OPTOPT}" in
    'list1'  ) list1="${OPTARG}";;
    'list2'  ) list2="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${list1}" ] || [ -z "${list2}" ] && return "${FAIL}"
  
  union --s1 "$( list_data --object "${list1}" )" --s2 "$( list_data --object "${list2}" )" --non-file
  return $?
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/numerics.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/hashmaps.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/set_operations.sh"
fi

__initialize_list
__prepared_list
