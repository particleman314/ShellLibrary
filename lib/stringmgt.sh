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
## @Software Package : Shell Automated Testing -- String management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.43
#
###############################################################################

###############################################################################
#
# Functions Supplied :
#
#    capitalize
#    escapify
#    get_extension
#    get_repeated_char_sequence
#    is_empty
#    join
#    print_no
#    print_plain
#    print_yes
#    quote
#    remove_extension
#    remove_whitespace
#    repeat
#    scan_for_errors
#    strindex
#    strstr
#    to_lower
#    to_upper
#    trim
#
###############################################################################

# shellcheck disable=SC2016,SC2068,SC2039,SC1117,SC2181

__STD_REPEAT_CHAR='='

__initialize_stringmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_debugging "${SLCF_SHELL_TOP}/lib/debugging.sh"
  
  __initialize "__initialize_stringmgt"
}

__prepared_stringmgt()
{
  __prepared "__prepared_stringmgt"
}

capitalize()
{
  __debug $@
  
  typeset response=
  
  typeset item=
  for item in $@
  do
    response+="$( printf "%s\n" "${item}" | \awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1' ) "
  done
  
  printf "%s\n" "${response}"
  return "${PASS}"
}

escapify()
{
  __debug $@
  
  typeset result="$1"
  typeset cycles=${2:-1}
  typeset count=0

  while [ "${count}" -lt "${cycles}" ]
  do
    result="$( printf "%q\n" "${result}" | \sed -e 's/\\/\\\\/g' )"
    count=$(( count + 1 ))
  done
  
  print_plain --message "${result}"
  return "${PASS}"
}

get_extension()
{
  __debug $@

  typeset str="$1"
  [ -z "${str}" ] && return "${PASS}"
  typeset ext="${str##*.}"
  [ "${ext}" != "${str}" ] && printf "%s\n" "${ext}"
  return "${PASS}"
}

get_repeated_char_sequence()
{
  __debug $@

  typeset repeat_char="${__STD_REPEAT_CHAR}"
  typeset count="${COLUMNS}"

  [ -z "${count}" ] && count=80

  OPTIND=1
  while getoptex "r. repeat-char. c. count." "$@"
  do
    case "${OPTOPT}" in
    'c'|'count'       ) count="${OPTARG}";;
    'r'|'repeat-char' ) repeat_char="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${count}" )" -eq "${YES}" ] || [ "${count}" -lt 0 ] && count="${COLUMNS}"
  [ "${count}" -le 0 ] && return "${FAIL}"

  #count=$(( count - 1 ))
  [ "$( is_empty --str "${count}" )" -eq "${YES}" ] || [ "${count}" -lt 1 ] && return "${FAIL}"

  typeset line="$( repeat --repeat-char "${repeat_char}" --number-times "${count}" )"
  typeset RC=$?

  # Fallback mechanism for making repeated string
  if [ "${RC}" -ne "${PASS}" ]
  then
    typeset cnt=0
    line=
    while [ "${cnt}" -lt "${count}" ]
    do
      line="${line}${repeat_char}"
      cnt="${#line}"
    done
  fi

  [ -z "${line}" ] && return "${FAIL}"
  print_plain --message "${line}"
  return "${PASS}"
}

is_empty()
{
  __debug $@
  
  typeset teststr=
  typeset allow_space="${NO}"
  
  OPTIND=1
  while getoptex "s. str. a allow-space" "$@"
  do
    case "${OPTOPT}" in
    's'|'str'         ) teststr="${OPTARG}";;
    'a'|'allow-space' ) allow_space="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${teststr}" ]
  then
    print_yes
    return "${PASS}"
  fi

  [ "${allow_space}" -eq "${NO}" ] && teststr="$( remove_whitespace "${teststr}" )"

  if [ -z "${teststr}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

join()
{
  __debug $@

  typeset components=
  typeset separator=' '

  OPTIND=1
  while getoptex "d: data: s. separator." "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'        ) components="${OPTARG}";;
    's'|'separator'   ) separator="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${components}" )" -eq "${YES}" ] && return "${FAIL}"
  printf "%s\n" "${components}" | \sed -e "s# #${separator}#g"
  return "${PASS}" 
}

print_no()
{
  print_plain --message "${NO}"
}

print_plain()
{
  typeset msg=
  typeset format='%b\n'
  
  OPTIND=1
  while getoptex "m. message. msg. f: format:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'message'|'msg' ) msg="${OPTARG}";;
    'f'|'format'        ) format="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  # shellcheck disable=SC2059
  [ -n "${msg}" ] && printf "${format}" "${msg}"
}

print_yes()
{
  print_plain --message "${YES}"
  return $?
}

quote()
{
  printf %s\\n "$1" | \sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
  return "${PASS}"
}

remove_extension()
{
  __debug $@

  typeset str="$1"
  [ -z "${str}" ] && return "${PASS}"
  str="${str%.*}"

  printf "%s\n" "${str}"
  return "${PASS}"
}

remove_whitespace()
{
  __debug $@
  
  typeset str="$1"
  [ -z "${str}" ] && return "${PASS}"
  str="$( printf "%s\n" "${str}" | \sed -e 's# ##g' )"
  printf "%s\n" "${str}"
  return "${PASS}"
}

repeat()
{
  __debug $@

  typeset repeat_str=
  typeset number_times=
  typeset use_space="${NO}"
  
  OPTIND=1
  while getoptex "r: repeat-char: n: number-times: use-space" "$@"
  do
    case "${OPTOPT}" in
    'r'|'repeat-char'  ) repeat_str="${OPTARG}";;
    'n'|'number-times' ) number_times="${OPTARG}";;
        'use-space'    ) use_space="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${use_space}" -eq "${NO}" ] && [ "$( is_empty --str "${repeat_str}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${number_times}" )" -eq "${YES}" ] || [ "${number_times}" -le 0 ] && return "${FAIL}"

  typeset result=
  if [ "${use_space}" -eq "${NO}" ]
  then
    result="$( \yes "${repeat_str}" | \head -n "${number_times}" | \paste -s -d ' ' - | \sed -e 's# ##g' )"
  else
    result="$( printf "%${number_times}s" ' ' )"
  fi
  
  [ -z "${result}" ] && return "${FAIL}"
  print_plain --message "${result}"
  return "${PASS}"
}

scan_for_errors()
{
  __debug $@

  typeset filename
  typeset error_regex=
  typeset RC

  OPTIND=1
  while getoptex "r: regex: f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'  ) filename="${OPTARG}";;
    'r'|'regex'     ) error_regex+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ]
  then
    printf "%d\n" "${PASS}"
  else
    if [ ! -f "${filename}" ]
    then
      printf "%d\n" "${PASS}"
    else
      typeset r=
      for r in ${error_regex}
      do
        \grep -q "${r}" "${filename}"
        RC=$?
        if [ "${RC}" -eq "${PASS}" ]
        then
          printf "%d\n" "${FAIL}"
          break
        fi
      done
    fi
  fi
  return "${PASS}"
}

strindex()
{
  __debug $@

  if [ $# -lt 2 ]
  then
    printf "%d\n" '-1'
  else
    typeset x="${1%%$2*}"
    if [ "${x}" == "$1" ]
    then
      printf "%d\n" '-1'
    else
      printf "%d\n" $(( ${#x} + 1 ))
    fi
  fi

  return "${PASS}"
}

strstr()
{
  __debug $@

  [ $# -lt 1 ] && return "${FAIL}"
  [ "${1#*$2*}" == "$1" ] && return "${FAIL}"
  return "${PASS}"
}

to_lower()
{
  __debug $@

  [ "$( is_empty --str "$1" )" -eq "${YES}" ] && return "${PASS}"
  print_plain --message "$1" | \tr "[:upper:]" "[:lower:]" 
}

to_upper()
{
  __debug $@

  [ "$( is_empty --str "$1" )" -eq "${YES}" ] && return "${PASS}"
  print_plain --message "$1" | \tr "[:lower:]" "[:upper:]"
}

trim()
{
  __debug $@

  typeset str="$1"
  [ -z "${str}" ] && return "${PASS}"
  str="$( printf "%s\n" "${str}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )"
  printf "%s\n" "${str}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/debugging.sh"
fi

__initialize_stringmgt
__prepared_stringmgt
