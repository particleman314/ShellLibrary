#!/bin/sh
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
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Numerics
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.04
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __count_inputs
#    count_items
#    decrement
#    increment
#    is_numeric_data
#    number_digits
#    number_wrapping
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC2124,SC1003,SC1117,SC2181,SC2086

__count_inputs()
{
  typeset results=()
  typeset result=''
  typeset inside=''
  typeset string="$@"
  typeset i

  for (( i=0 ; i<${#string} ; i++ ))
  do
    typeset char=${string:i:1}
    if [ -n "${inside}" ]
    then
      if [ "${char}" == '\' ]
      then
        if [ "${inside}" == "\"" ] && [ "${string:i+1:1}" == "\"" ]
        then
          i=$( i + 1)
          char="${inside}"
        fi
      elif [ "${char}" == "${inside}" ]
      then
        inside=''
      fi
    else
      if [ "${char}" == "\"" ] || [ "${char}" == "'" ]
      then
        inside="${char}"
      elif [ "${char}" == " " ]
      then
        char=''
        results+=("${result}")
        result=''
      fi
    fi
    result+="${char}"
  done

  [ -n "${result}" ] && results+=("${result}")

  typeset count_args="${#results[@]}"
  printf "%d\n" "${count_args}"
  return "${PASS}"
}

__initialize_numerics()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    
  #SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
  #SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
  #SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"

  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  
  __initialize "__initialize_numerics"
}

__prepared_numerics()
{
  __prepared "__prepared_numerics"
}

count_items()
{
  typeset data=
  typeset separator="${IFS}"

  OPTIND=1
  while getoptex "d: data: s: separator:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'      ) data="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${data}" ]
  then
    printf "%d" 0
    return "${PASS}"
  fi

  if [ "${separator}" != "${IFS}" ]
  then
    OLDIFS="${IFS}"
    IFS="${separator}"

    set -- ${data}
    typeset count=$#
    [ "x${data:0:1}" == "x${separator}" ] && count=$(( count - 1 ))
    printf "%d" "${count}"
    IFS="${OLDIFS}"
  else
    data="$( printf "%s " ${data} )"
    printf "%d\n" "$( __count_inputs "${data}" )"
  fi    
  return "${PASS}"
}

decrement()
{
  typeset oldvalue=${1:-0}
  typeset incval=${2:-1}
  
  (( oldvalue = oldvalue - incval ))
  printf "%s\n" "${oldvalue}"
  return "${PASS}"
}

increment()
{
  typeset oldvalue=${1:-0}
  typeset incval=${2:-1}
  
  oldvalue=$(( oldvalue + incval ))
  printf "%s\n" "${oldvalue}"
  return "${PASS}"
}

is_numeric_data()
{
  typeset data=

  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'   ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${data}" ]
  then
    printf "%d\n" "${NO}"
    return "${FAIL}"
  fi

  typeset result=$( \awk -v a="${data}" 'BEGIN {print (a == a + 0)}' )
  printf "%d\n" "${result}"
  return "${PASS}"
}

number_digits()
{
  typeset input="$1"

  if [ -z "${input}" ] || [ "$( is_numeric --data "${input}" )" -eq "${NO}" ]
  then
    printf "%d\n" -1
    return "${FAIL}"
  fi

  typeset size="$( printf "%s\n" "define trunc(x) { auto s; s=scale; scale=0; x=x/1; scale=s; return x }; trunc(l(${input})/l(10))+1" | \bc -l )"
  printf "%s\n" "${size}"
  return "${PASS}"
}

number_wrapping()
{  
  typeset oldvalue=0
  typeset wrapval=1

  OPTIND=1
  while getoptex "d: data: w: wrap:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'   ) oldvalue="${OPTARG}";;
    'w'|'wrap'   ) wrapval="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "${wrapval}" -ne 0 ] && oldvalue=$( printf "%s\n" "${oldvalue}%${wrapval}" | \bc )
  printf "%s\n" "${oldvalue}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
fi

__initialize_numerics
__prepared_numerics
