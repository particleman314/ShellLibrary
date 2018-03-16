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
## @Software Package : Shell Automated Testing -- Argument Parsing
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.21
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __handle_quoted_word
#    __remove_cmdline_quotations
#    contains_option
#    getoptex
#    opthandler
#    optlistex
#    remove_option
#
###############################################################################

# shellcheck disable=SC2016,SC1090,SC2039,SC2086,SC1117

[ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

# shellcheck source=/dev/null

[ -z "${PASS}" ] && . "${SLCF_SHELL_TOP}/lib/constants.sh"
[ -z "${__SLCF_ARGPARSING_ERROR_LOG}" ] && __SLCF_ARGPARSING_ERROR_LOG="$( \pwd -L )/.argparsing.err"

## @fn __handle_quoted_word()
__handle_quoted_word()
{
  QUOTE_SHIFT_COUNTER=0
  shift
  
  if [ "${1:0:1}" == "'" ]
  then
    QUOTE_SHIFT_COUNTER=$(( QUOTE_SHIFT_COUNTER + 1 ))
    OPTARG="$1"
    while [ "${OPTARG: -1}" != "'" ]
    do
      shift
      OPTARG+=" $1"
      QUOTE_SHIFT_COUNTER=$(( QUOTE_SHIFT_COUNTER + 1 ))
    done
    OPTIND=$(( OPTIND + QUOTE_SHIFT_COUNTER ))
  else
    if [ "${1:0:1}" == "\"" ]
    then
      QUOTE_SHIFT_COUNTER=$(( QUOTE_SHIFT_COUNTER + 1 ))
      OPTARG="$1"
      while [ "${OPTARG: -1}" != "\"" ]
      do
        shift
        OPTARG+=" $1"
        QUOTE_SHIFT_COUNTER=$(( QUOTE_SHIFT_COUNTER + 1 ))
      done
      OPTIND=$(( OPTIND + QUOTE_SHIFT_COUNTER ))
    fi
  fi
  
  return "${PASS}"
}

## @fn __remove_cmdline_quotations()
__remove_cmdline_quotations()
{
  ###
  ### Strip away the quotations from OPTARG
  ###
  OPTARG="$( printf "%s\\n" "${OPTARG:1:${#OPTARG}-2}" )"
  return "${PASS}"
}

## @fn contains_option()
contains_option()
{
  typeset option2find=$( printf "%s\n" "$1" | \tr '|' ' ' )
  shift
  
  if [ -z "${option2find}" ]
  then
    printf "%s\n" "${NO}"
    return "${FAIL}"
  fi

  typeset arg=
  for arg in $*
  do
    for o2f in ${option2find}
    do
      typeset dash='-'
      [ ${#o2f} -gt 1 ] && dash='--'
      if [ "${arg}" == "${dash}${o2f}" ]
      then
        printf "%s\n" "${YES}"
        return "${PASS}"
      fi
    done
  done

  printf "%s\n" "${NO}"
  return "${FAIL}"
}

# Handle options which need to be addressed
# Special characters can appear at the and of option names specifying
# whether an argument is required (default is ";"):
# ";" (default) -- no argument
# ":" -- required argument
# "." -- optional argument
## @fn getoptex()
getoptex()
{
  QUOTE_SHIFT_COUNTER=0
  OPTERR=
  OPTRET="${PASS}"
  let $# || return "${FAIL}"
  typeset optlist="${1#;}"
  let OPTIND || OPTIND=1
  [ ${OPTIND} -lt $# ] || return "${FAIL}" 
  shift ${OPTIND}
  
  if [ "$1" != "-" ] && [ "$1" != "${1#-}" ]
  then
    OPTIND=$((OPTIND+1))
    if [ "$1" != "--" ]
    then
      typeset o
      o="-${1#-${OPTOFS}}"
      for opt in ${optlist#;}
      do
        QUOTE_SHIFT_COUNTER=0
	      OPTOPT="${opt%[;.:]}"
	      unset OPTARG
        unset OPTTYPE
	      OPTTYPE="${opt##*[^;:.]}"
	      [ -z "${OPTTYPE}" ] && OPTTYPE=';'
        
	      if [ ${#OPTOPT} -gt 1 ]
        then # long-named option
          OPTSHORT="${NO}"
          case "${o}" in
          "--${OPTOPT}")
            if [ "${OPTTYPE}" != ':' ]
	          then
	            if [ "${OPTTYPE}" == '.' ]
              then
                __handle_quoted_word "$@"
                if [ "${QUOTE_SHIFT_COUNTER}" -eq 0 ]
                then
                  OPTARG="$2"
                else
                  shift ${QUOTE_SHIFT_COUNTER}
                fi
              fi
	            [ "${OPTTYPE}" != ';' ] && [ "${OPTARG:0:1}" != '-' ] && OPTIND=$((OPTIND+1))
              QUOTE_SHIFT_COUNTER=0
	            return "${PASS}"
	          fi
            
            __handle_quoted_word "$@"
            if [ "${QUOTE_SHIFT_COUNTER}" -eq 0 ]
            then
              OPTARG="$2"
            else
              shift ${QUOTE_SHIFT_COUNTER}
            fi

	          if [ -z "${OPTARG}" ]
	          then # error: must have an agrument
	            OPTERR="$0: error: ${OPTOPT} must have an argument"
	            OPTARG="${OPTOPT}"
	            OPTOPT="?"
              OPTRET="${FAIL}"
              QUOTE_SHIFT_COUNTER=0
	            return "${FAIL}"
	          fi
	          OPTIND=$((OPTIND + 1)) # skip option argument
            QUOTE_SHIFT_COUNTER=0
	          return "${PASS}"
	          ;;
          "--${OPTOPT}="*)
            if [ "${OPTTYPE}" == ';' ]
	          then  # error: must not have arguments
	            OPTERR="$0: error: ${OPTOPT} must not have arguments"
	            OPTARG="${OPTOPT}"
	            OPTOPT="?"
              OPTRET="${FAIL}"
              QUOTE_SHIFT_COUNTER=0
	            return "${FAIL}"
	          fi
            typeset replacement="--${OPTOPT}="
	          OPTARG=${o#${replacment}}
            QUOTE_SHIFT_COUNTER=0
	          return "${PASS}"
	          ;;
          esac
	      else # short-named option
          OPTSHORT="${YES}"
	        case "${o}" in
	        "-${OPTOPT}")
	          unset OPTOFS
	          if [ "${OPTTYPE}" != ':' ]
            then
	            if [ "${OPTTYPE}" == '.' ]
              then
                __handle_quoted_word "$@"
                if [ "${QUOTE_SHIFT_COUNTER}" -eq 0 ]
                then
                  OPTARG="$2"
                else
                  shift ${QUOTE_SHIFT_COUNTER}
                fi
              fi
	            [ "${OPTTYPE}" != ';' ] && [ "${OPTARG:0:1}" != '-' ] && OPTIND=$((OPTIND+1))
              QUOTE_SHIFT_COUNTER=0
	            return "${PASS}"
	          fi
            
            __handle_quoted_word "$@"
            if [ "${QUOTE_SHIFT_COUNTER}" -eq 0 ]
            then
              OPTARG="$2"
            else
              shift ${QUOTE_SHIFT_COUNTER}
            fi
            
	          if [ -z "${OPTARG}" ]
	          then
	            OPTERR="$0: error: -${OPTOPT} must have an argument"
	            OPTARG="${OPTOPT}"
	            OPTOPT="?"
              OPTRET="${FAIL}"
	            return "${FAIL}"
	          fi

            OPTIND=$((OPTIND + 1)) # skip option argument
            QUOTE_SHIFT_COUNTER=0
	          return "${PASS}"
	          ;;
          "-${OPTOPT}"*)
            if [ "${OPTTYPE}" == ';' ]
	          then # an option with no argument is in a chain of options
	            OPTOFS="${OPTOFS}?" # move to the next option in the chain
	            OPTIND=$((OPTIND-1)) # the chain still has other options
	          else
	            unset OPTOFS
	            OPTARG="${o#-${OPTOPT}}"
	          fi
            QUOTE_SHIFT_COUNTER=0
	          return "${PASS}"
	          ;;
          esac
	      fi
      done
      
      if [ -z "${OPTALLOW_ALL}" ] || [ "${OPTALLOW_ALL}" -eq "${NO}" ]
      then
        OPTERR="$0: error: invalid option: << ${o} >>"
        OPTRET="${FAIL}"
      else
        OPTOPT="${o}"
        QUOTE_SHIFT_COUNTER=0
        return "${PASS}"
      fi
    fi
  fi
  
  OPTOPT="?"
  if [ "${OPTRET}" -eq 1 ]
  then
    SAVE_OPTARG="${OPTARG}"
    SAVE_OPTOPT="${OPTOPT}"
    SAVE_OPTERR="${OPTERR}"
  fi
  
  QUOTE_SHIFT_COUNTER=0
  return "${FAIL}"
}

## @fn opthandler()
opthandler()
{
  typeset optlist=
  optlist=$( optlistex "$1" )
  shift
 
  typeset args=$*
  OPTIND=1
  getoptex "${optlist}" ${args}
  typeset RC=$?
  return "${RC}"
}

## @fn optlistex()
optlistex()
{
  typeset l="$1"
  typeset m= # mask
  typeset r= # to store result
  while [ ${#m} -lt $((${#l}-1)) ]
  do
    m="$m?"
  done # create a "???..." mask
    
  while [ -n "$l" ]
  do
    r="${r:+"$r "}${l%$m}" # append the first character of $l to $r
    l="${l#?}" # cut the first charecter from $l
    m="${m#?}"  # cut one "?" sign from m
    if [ -n "${l%%[^:.;]*}" ]
    then # a special character (";", ".", or ":") was found
      r="$r${l%$m}" # append it to $r
      l="${l#?}" # cut the special character from l
      m="${m#?}"  # cut one more "?" sign
    fi
  done
  [ -n "${r}" ] && printf "%s\n" "$r"
  return "${PASS}"
}

## @fn remove_option()
remove_option()
{
  typeset num_removals="$1"
  shift

  typeset rmkeys=
  typeset count=0
  while [ "${count}" -lt "${num_removals}" ]
  do
    typeset rk="$1"
    if [ "${rk%%:}" != "${rk}" ]
    then
      rk="${rk}:0:1"
    fi
    if [ -z "${rmkeys}" ]
    then
      rmkeys="${rk}"
    else
      rmkeys+=" ${rk}"
    fi
    count=$(( count + 1 ))
    shift
  done

  typeset cmdline=$*
  
  typeset rk
  for rk in ${rmkeys}
  do
    typeset k=$( printf "%s" "${rk}" | \cut -f 1 -d ':' )
    typeset nopt=$( printf "%s" "${rk}" | \cut -f 2 -d ':' )
    typeset longopt=$( printf "%s" "${rk}" | \cut -f 3 -d ':' )

    typeset prefix='-'
    [ "${longopt}" -eq 1 ] && prefix='--'

    ###
    ### Find the corresponding entry in the commandline ( if it exists )
    ###
    typeset entry
    typeset begin=1
    for entry in $cmdline
    do
      [ "${prefix}${k}" == "${entry}" ] && break
      begin=$(( begin + 1 ))
    done
    
    [ "${begin}" -eq 0 ] && continue
    typeset end=$(( begin + nopt ))
   
    ###
    ### Count represents starting location, shift_amount shows how much
    ###   to remove from the "cmdline"
    ###
    typeset orig_end=${end}
    typeset word="$( printf "%s\n" "${cmdline}" | \cut -d " " -f ${end} )"
    if [ "${word:0:1}" == "'" ]
    then
      while [ "${word: -1}" != "'" ]
      do
        end=$(( end + 1 ))
        word="$( printf "%s\n" "${cmdline}" | \cut -d " " -f ${orig_end}-${end} )"
      done
    fi
    if [ "${word:0:1}" == "\"" ]
    then
      while [ "${word: -1}" != "\"" ]
      do
        end=$(( end + 1 ))
        word="$( printf "%s\n" "${cmdline}" | \cut -d " " -f ${orig_end}-${end} )"
      done
    fi
    
    cmdline=$( printf "%s\n" "${cmdline}" | \awk -v f=${begin} -v t=${end} '{for(i=1;i<=NF;i++)if(i>=f&&i<=t)continue;else printf("%s%s",$i,(i!=NF)?OFS:ORS)}' )
  done  
 
  [ -n "${cmdline}" ] && printf "%s\n" "${cmdline}"
  return "${PASS}"
}
