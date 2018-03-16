#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2015.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Time Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.35
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __change_time_to_HMS
#    __change_time_to_local
#    __change_time_to_UTC
#    __conversion_time_helper
#    __extract_time_unit
#    __extract_hours
#    __extract_minutes
#    __extract_seconds
#    __get_time_unit_conversion
#    __today
#    __today_mdy
#    __today_as_seconds
#    calculate_run_time
#    convert_time
#    convert_to_seconds
#    show_start_time
#    show_end_time
#    show_elapsed_time
#
###############################################################################

# shellcheck disable=SC2016,SC2068,SC2039,SC1117,SC2145,SC2181,SC2094

__change_time_to_HMS()
{
  __debug $@
  
  typeset numsecs=
  typeset digitize="${NO}"
  
  OPTIND=1
  while getoptex "n: num-seconds: d: digitize:" "$@"
  do
    case "${OPTOPT}" in
	  'n'|'num-seconds' ) numsecs="${OPTARG}";;
    'd'|'digitize'    ) digitize="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${numsecs}" ]
  then
	print_plain --message "0 [hrs] 0 [mins] 0 [secs]"
	return "${PASS}"
  fi

  typeset numhours="$( print_plain --message "${numsecs} / 3600" | \bc )"
  numsecs="$( print_plain --message "${numsecs} - ( ${numhours} * 3600 )" | \bc )"

  [ -z "${numsecs}" ] && numsecs=0
  [ "${digitize}" -eq "${YES}" ] && [ "${numhours}" -le 9 ] && numhours="0${numhours}"
  
  typeset numminutes="$( print_plain --message "${numsecs} / 60" | \bc )"
  numsecs="$( print_plain --message "${numsecs} - ( ${numminutes} * 60 )" | \bc )"

  [ "${digitize}" -eq "${YES}" ] && [ "${numminutes}" -le 9 ] && numminutes="0${numminutes}"
  [ "${digitize}" -eq "${YES}" ] && [ "${numsecs}" -le 9 ] && numsecs="0${numsecs}"
  
  print_plain --message "${numhours} [hrs] ${numminutes} [mins] ${numsecs} [secs]"
  return "${PASS}"
}

__change_time_to_local()
{
  typeset epochtime="$1"
  typeset timeformat='+%c'

  if [ -n "${epochtime}" ]
  then
    \which 'adb' >/dev/null 2>&1
    if [ $? -eq "${PASS}" ]
    then
      printf "%s\n" "${epochtime}" | \adb | \tr -s ' ' | \sed -e 's#^ ##' | \date "${timeformat}"
    else
      __conversion_time_helper "${epochtime}" "${timeformat}"
    fi
    return "${PASS}"
  fi
  return "${FAIL}"
}

__change_time_to_UTC()
{
  typeset epochtime="$1"
  typeset timeformat="${2:-"+%FT%T"}"

  if [ -z "${epochtime}" ]
  then
    printf "%s\n" "1900-01-01T00:00:00"
    return "${FAIL}"
  fi

  \which "adb" >/dev/null 2>&1
  if [ $? -eq "${PASS}" ]
  then
    printf "%s\n" "0t${epochtime}" | \adb | \tr -s ' ' | \sed -e 's#^ ##' | \date -u "${timeformat}"
  else
    __conversion_time_helper "${epochtime}" "${timeformat}"
  fi
  return "${PASS}"
}

__conversion_time_helper()
{
  typeset epochtime="$1"
  typeset timeformat="$2"

  typeset result="$( \date -d "@${epochtime}" "${timeformat}" 2>&1 )"
  typeset RC=$?
  printf "%s\n" "${result}" | \grep -q 'usage'
  typeset bad_usage=$?
  if [ "${RC}" -ne "${PASS}" ] || [ "${bad_usage}" -eq "${PASS}" ]
  then
    result="$( \date -r "${epochtime}" "${timeformat}" )"
  fi
  printf "%s\n" "${result}"
  return "${PASS}"
}

__extract_time_unit()
{
  __debug $@

  typeset timescale

  OPTIND=1
  while getoptex "t: time-unit:" "$@"
  do
    case "${OPTOPT}" in
    't'|'time-unit' )  timescale="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $# -lt 1 ] && return "${FAIL}"

  typeset result=
  case "${timescale}" in
  'hours'   ) result="$( printf "%s " $@ | \cut -f 1 -d ' ' )";;
  'minutes' ) result="$( printf "%s " $@ | \cut -f 3 -d ' ' )";;
  'seconds' ) result="$( printf "%s " $@ | \cut -f 5 -d ' ' )";;
  esac

  [ -n "${result}" ] && print_plain --message "${result}"
  return "${PASS}"
}

__extract_hours()
{
  __debug $@
  __extract_time_unit --time-unit hours "$( printf "%s\n" "$@" | \sed -e 's#Elapsed Time ::# #' | \tr -s ' ' )"
}

__extract_minutes()
{
  __debug $@
  __extract_time_unit --time-unit minutes "$( printf "%s\n" "$@" | \sed -e 's#Elapsed Time ::# #' | \tr -s ' ' )"
}

__extract_seconds()
{
  __debug $@
  __extract_time_unit --time-unit seconds "$( printf "%s\n" "$@" | \sed -e 's#Elapsed Time ::# #' | \tr -s ' ' )"
}

__get_time_unit_conversion()
{
  __debug $@

  typeset from=
  typeset to=
  typeset called=0

  OPTIND=1
  while getoptex "f: from: t: to: call:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'from'  )  from="${OPTARG}";;
    't'|'to'    )  to="${OPTARG}";;
        'call'  )  called="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${from}" ] || [ -z "${to}" ] && return "${FAIL}"

  typeset linkset="${from}_${to}"
  typeset converter=

  if [ "${from}" == "${to}" ]
  then
    printf "%d\n" 1
    return "${PASS}"
  fi

  case "${linkset}" in
  'months_seconds' ) converter=2592000;;
  'months_minutes' ) converter=43200;;
  'months_hours'   ) converter=720;;
  'months_days'    ) converter=30;;  ## Canonical value
  'months_weeks'   ) converter=4;;   ## Canonical value
  'weeks_seconds'  ) converter=604800;;
  'weeks_minutes'  ) converter=10080;;
  'weeks_hours'    ) converter=168;;
  'weeks_days'     ) converter=7;;
  'days_seconds'   ) converter=86400;;
  'days_minutes'   ) converter=1440;;
  'days_hours'     ) converter=24;;
  'hours_seconds'  ) converter=3600;;
  'hours_minutes'  ) converter=60;;
  'minutes_seconds') converter=60;;
  esac

  if [ -z "${converter}" ] && [ "${called}" -lt 1 ]
  then
    converter="$( __get_time_unit_conversion --from "${to}" --to "${from}" --call $(( called + 1 )) )"
    converter="$( printf "%s\n" "scale=3; 1.0/${converter}" | \bc )"
  fi

  [ -z "${converter}" ] && return "${FAIL}"
  
  printf "%s\n" "${converter}"
  return "${PASS}"
}

__initialize_timemgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  __load __initialize_stringmgt "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"

  __initialize "__initialize_timemgt"
}

__prepared_timemgt()
{
  __prepared "__prepared_timemgt"
}

__today()
{
   print_plain --message "$( \date )"
  return "${PASS}" 
}

__today_mdy()
{
  print_plain --message "$( \date "+%m_%d_%Y" )"
  return "${PASS}"
}

__today_as_seconds()
{
  print_plain --message "$( \date "+%s" )"
  return "${PASS}"
}

calculate_run_time()
{
  __debug $@
  
  typeset startfile=
  typeset endfile=
  typeset timescale='1'
  typeset scale=3

  OPTIND=1
  while getoptex "s: start: e: end: t. timescale. decimals:" "$@"
  do
    case "${OPTOPT}" in
    's'|'start'     )  startfile="${OPTARG}";;
    'e'|'end'       )  endfile="${OPTARG}";;
    't'|'timescale' )  timescale="${OPTARG}";;
        'decimals'  )  scale="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${startfile}" ] || [ -z "${endfile}" ]
  then
    printf "%f" "-1.0"
    return "${FAIL}"
  fi
 
  typeset start=0
  typeset end=0
  typeset line=
 
  if [ -f "${startfile}" ]
  then
   typeset cnt=0
    while read -u 8 -r line
    do
      start="${line}"
      if [ "${startfile}" == "${endfile}" ] && [ "${cnt}" -eq 1 ]
      then
        end="${line}"
        break
      fi
      cnt=$(( cnt + 1 ))
    done 8< "${startfile}"
  else
    [ -n "${startfile}" ] && start="${startfile}"
  fi
  
  if [ -f "${endfile}" ]
  then
    if [ "${startfile}" != "${endfile}" ]
    then
      while read -u 8 -r line
      do
        end="${line}"
      done 8< "${endfile}"
    fi
  else
    [ -n "${endfile}" ] && end="${endfile}"    
  fi
  
  typeset diff="$( printf "%s\n" "scale=${scale}; (${end} - ${start}) / ${timescale}" | \bc )"
  print_plain --message "${diff}"
  
  [ -f "${startfile}" ] && \rm -f "${startfile}"
  [ -f "${endfile}" ] && \rm -f "${endfile}"
  
  return "${PASS}"
}

convert_time()
{
  __debug $@
  
  typeset timestyle=std
  typeset numsecs=0
  typeset always_use_two_digits="${NO}"

  OPTIND=1
  while getoptex "s. timestyle. n: num-seconds: match-digits" "$@"
  do
    case "${OPTOPT}" in
    's'|'timestyle'    ) timestyle="${OPTARG}";;
    'n'|'num-seconds'  ) numsecs="${OPTARG}";;
        'match-digits' ) always_use_two_digits="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset newtime="${numsecs} [secs]"
  
  case "${timestyle}" in
  'std' ) newtime=$( __change_time_to_HMS --num-seconds "${numsecs}" --digitize "${always_use_two_digits}" );;
  esac
    
  print_plain --message "${newtime}"
  return "${PASS}"
}

convert_to_seconds()
{
  __debug $@

  typeset result=
  if [ "$( is_numeric_data --data "$@" )" -eq "${YES}" ]
  then
    result="$( \date --date="@$@" "+%s" 2>&1 )"
  else
    result="$( \date --date="$@" "+%s" 2>&1 )"
  fi

  typeset RC=$?
  echo "${result} --- ${RC}" >>/tmp/.xyz
  printf "%s\n" "${result}" | \grep -q 'usage'
  typeset bad_usage=$?
  if [ "${RC}" -ne "${PASS}" ] || [ "${bad_usage}" -eq "${PASS}" ]
  then
    result="$( \date -j -f "%a %b %d %T %Z %Y" "$@" "+%s" )"
    echo "REDO : ${result}" >>/tmp/.xyz
  fi
  print_plain --message "${result}"
  return "${PASS}"
}

show_start_time()
{
  __debug $@
  
  start_time="${1:-$( \date "+%s" )}"
  print_plain --message "Start Time :: ${start_time} (POSIX)"
}

show_end_time()
{
  __debug $@

  end_time="${1:-$( \date "+%s" )}"
  print_plain --message "End Time :: ${end_time} (POSIX)"
}

show_elapsed_time()
{
  __debug $@

  typeset start_time=
  
  OPTIND=1
  while getoptex "s: start-time:" "$@"
  do
    case "${OPTOPT}" in
    's'|'start-time' ) start_time="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${start_time}" ]
  then
    print_plain --message "Elapsed Time :: -1 [secs]"
    return "${FAIL}"
  fi
 
  typeset end_time="$( \date "+%s" )"

  typeset difftime="$(( end_time - start_time ))"
  typeset difftime_human="$( convert_time --num-seconds "${difftime}" )"

  print_plain --message "Elapsed Time :: ${difftime_human}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
fi

__initialize_timemgt
__prepared_timemgt
