#!/usr/bin/env bash
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
## @Software Package : Shell Automated Testing -- Setup
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.46
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __add_junk_file
#    __calculate_file_size
#    __cleanup_junk_files
#    __decorate
#    __determine_tabbing_depth
#    __get_char_count
#    __get_line_count
#    __get_sequence
#    __get_word_count
#    __group_line_counts
#    __has_installed
#    __initialize
#    __load
#    __prepared
#    __range_limit
#    __rest_in_sequence
#    __set2globals
#    __strip_quotes
#    __translate_rc
#    __unix_prefix_trim
#    __unix_suffix_trim
#    add_element
#    add_trap_callback
#    begin_initialized
#    convert_pf_yn
#    copy_file_segment
#    default_value
#    end_timer
#    end_initialized 
#    fn_exists
#    generate_checksums
#    get_bit_setting
#    get_element
#    get_function_names
#    get_line_length
#    get_user_id
#    get_user_id_home
#    interpret_yn
#    invert
#    is_false
#    is_true
#    next_in_sequence
#    pause
#    popd
#    progress_bar
#    pushd
#    remove_color_coding
#    remove_element
#    replace_element
#    rest_in_sequence
#    show_loaded
#    sleep_func
#    spinner
#    sprintf
#    start_timer
#    timer
#
###############################################################################

# shellcheck disable=SC1117,SC2039,SC2120,SC2068,SC2119,SC2016,SC2059,SC1003,SC2086,SC2017

if [ -z "${INDENTATION_DEBUG_LEVEL}" ]
then
  INDENTATION_DEBUG_LEVEL=0
  INDENTATION_SIZE=4
  TABBING=
  DECORATION_STRING='_inner_'
  REGISTRY=
  JUNK_FILES=

  unset __DIR_STACK
  export __DIR_STACK
fi

__add_junk_file()
{
  typeset fn="$1"
  typeset flag="${2:-${YES}}"

  if [ "${flag}" -eq "${YES}" ]
  then
    [ -f "${fn}" ] && JUNK_FILES="${JUNK_FILES} ${fn}"
  else
    JUNK_FILES="${JUNK_FILES} ${fn}"
  fi
  return "${PASS}"
}

__calculate_filesize()
{
  typeset filename="$1"
  if [ -z "${filename}" ]
  then
    printf "%d\n" 0
    return "${FAIL}"
  fi
  typeset fs=$( __get_char_count "${filename}" )
  printf "%d\n" "${fs}"
  return "${PASS}"
}

__cleanup_junk_files()
{
  typeset numjunk=$( __get_word_count "${JUNK_FILES}" )
  [ "${numjunk}" -lt 1 ] && return "${PASS}"

  typeset f=

  while read -r -u 7 f
  do
    f="$( printf "%s\n" ${JUNK_FILES} | \head -n 1 )"
    [ -f "${f}" ] && \rm -f "${f}"
    JUNK_FILES="$( printf "%s\n" "${JUNK_FILES}" | \grep -v "^${f}$" | \tr -s ' ' )" #\sed -e "s#${f}##" | \tr -s ' ' )
  done 7< $( printf "%s\n" ${JUNK_FILES} )

  JUNK_FILES=
  return "${PASS}"
}

__decorate()
{
  eval "
    ${DECORATION_STRING}$(typeset -f "$1")
    $1"'() {
      __determine_tabbing_depth 1
      #echo >&2 "Calling function '"$1"' with $# arguments"
      ${DECORATION_STRING}'"$1"' "$@"
      typeset ret=$?
      #echo >&2 "Function '"$1"' returned with exit status $ret"
      __determine_tabbing_depth -1
      return "$ret"
    }'
}

__determine_tabbing_depth()
{
  typeset offset=$1
  [ -z "${offset}" ] && offset=0
  INDENTATION_DEBUG_LEVEL=$(( INDENTATION_DEBUG_LEVEL + offset ))

  typeset indentation
  typeset multiplier=$( printf "%s\n" "${INDENTATION_DEBUG_LEVEL} * ${INDENTATION_SIZE}" | \bc )
  #typeset multiplier=$(( INDENTATION_DEBUG_LEVEL * INDENTATION_SIZE ))
  indentation=$(( multiplier - 1 ))

  [ "${indentation}" -lt 0 ] && indentation=0

  TABBING=$( printf "%${indentation}s\\n" | \tr ' ' - )
  [ -n "${TABBING}" ] && TABBING="${TABBING}>"
  #printf "%s\n" "${INDENTATION_DEBUG_LEVEL}|${identation}|${INDENTATION_SIZE}|${TABBING}"
}

__get_char_count()
{
  __get_count_of_items 'characters' $@
  return $?
}

__get_count_of_items()
{
  typeset cnttype="$1"
  shift

  typeset linefeed=

  case "${cnttype}" in
  'c'|'char'|'characters'  ) cnttype='-c';;
  'l'|'line'|'lines'       ) cnttype='-l'; linefeed="\n";;
  'w'|'word'|'words'       ) cnttype='-w'; linefeed="\n";;
  esac

  typeset skip_file_usage="${NO}"

  OPTIND=1
  while getoptex "n non-file" "$@"
  do
    case "${OPTOPT}" in
    'n'|'non-file' ) skip_file_usage="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset item_count=

  if [ -z "$1" ]
  then
    printf "%d\n" 0
    return "${FAIL}"
  elif [ ! -f "$1" ] || [ "${skip_file_usage}" -eq "${YES}" ]
  then
    item_count=$( __unix_prefix_trim "$( printf "%s${linefeed}" $@ | \wc ${cnttype} )" )
  else
    item_count=$( __unix_prefix_trim "$( \wc ${cnttype} < "$1" )" )
  fi

  if [ -z "${item_count}" ]
  then
    item_count=0
  else
    item_count=$( printf "%s\n" "${item_count}" | \cut -f 1 -d ' ' )
    item_count=$(( item_count - offset ))
  fi
  printf "%d\n" "${item_count}"
  return "${PASS}"
}

__get_line_count()
{
  __get_count_of_items 'lines' $@
  return $?
}

__get_sequence()
{
  typeset stpt="$1"
  typeset endpt="$2"
  typeset stride="${3:-1}"

  [ -z "$1" ] || [ -z "$2" ] && return "${FAIL}"

  if [ "$1" -eq "$2" ]
  then
    printf "%d\n" "$1"
    return "${PASS}"
  fi

  typeset count="${stpt}"
  typeset listnumbers=

  if [ "${stride}" -gt 0 ]
  then
    while [ "${count}" -le "${endpt}" ]
    do
      listnumbers="${listnumbers} ${count}"
      count=$(( count + stride ))
    done
  elif [ "${stride}" -lt 0 ]
  then
    while [ "${count}" -ge "${endpt}" ]
    do
      listnumbers="${listnumbers} ${count}"
      count=$(( count + stride ))
    done
  fi

  [ -n "${listnumbers}" ] && \echo "${listnumbers}" #printf "%d\n" ${listnumbers}
  return "${PASS}"
} 

__get_word_count()
{
  __get_count_of_items 'words' $@
  return $?
}

__group_line_counts()
{
  typeset lid
  typeset groups
  typeset group_start_lid=
  typeset group_end_lid=

  for lid in $@
  do
    if [ -z "${group_start_lid}" ]
    then
      group_start_lid="${lid}"
      group_end_lid="${lid}"
      continue
    fi

    if [ $(( lid - group_end_lid )) -gt 1 ]
    then
      groups="${groups} ${group_start_lid}:${group_end_lid}"
      group_start_lid="${lid}"
      group_end_lid="${lid}"
    else
      group_end_lid="${lid}"
    fi
  done

  [ -n "${group_start_lid}" ] && [ -n "${group_end_lid}" ] && groups="${groups} ${group_start_lid}:${group_end_lid}"

  typeset result=$( printf "%s\n" "${groups}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )
  [ -n "${groups}" ] && printf "%s\n" "${result}"
  return "${PASS}"
}

__has_installed()
{
  typeset result="${NO}"
  if [ -z "$1" ]
  then
    printf "%d\n" "${result}"
    return "${FAIL}"
  fi
  
  printf "%s\n" ${REGISTRY} | \grep -q "$1"
  [ $? -eq "${PASS}" ] && result="${YES}"
  printf "%d\n" "${result}"
  return "${PASS}"
}

__initialize()
{
  begin_initialized "$1"
  typeset RC=$?
  [ ${RC} -eq "${FAIL}" ] && return "${FAIL}"

  #if [ 1 == 0 ]
  #then  
  #typeset skip_fn='begin_initialized end_initialized show_loaded get_function_names'

  #typeset funcnames=
  #typeset fn
  #funcnames=$( get_function_names )
  #for fn in ${funcnames}
  #do
  #  printf "%s\n" "${fn}" | \grep -q "^_" > /dev/null 2>&1
  #  RC=$?
  #  [ "${RC}" -eq "${PASS}" ] && continue

  #  printf "%s" "${skip_fn}" | \grep -q "${fn}" >/dev/null 2>&1
  #  RC=$?
  #  [ "${RC}" -eq "${PASS}" ] && continue

  #  type "${DECORATION_STRING}${fn}" 2>/dev/null | \grep -q 'is a function'
  #  RC=$?

  #  [ "${RC}" -eq "${PASS}" ] && continue
  #  __decorate "${fn}"
  #  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && printf "%s\n" "Decorating function : ${fn}"
  #done
  #fi

  typeset srcfile="$1"
  srcfile="${srcfile#__initialize_}"
  RC=1  
  if [ -n "${REGISTRY}" ]
  then
    printf "%s\n" "${REGISTRY}" | \grep -q "${srcfile}"
    RC=$?
  fi
  
  ### Maybe use a sort/uniq to do the same as awk
  if [ "${RC}" -eq 1 ]
  then
    REGISTRY="${REGISTRY} ${srcfile}"
    REGISTRY=$( printf "%s\n" "${REGISTRY}" | \tr ' ' '\n' | \awk '!seen[$0]++' | \tr '\n' ' ' )
  fi
  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && printf "%s\n" "Registry : ${REGISTRY}"
  end_initialized "$1"
}

__initialize_base_setup()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )
  
  # shellcheck source=/dev/null

  [ -z "${PASS}" ] && . "${SLCF_SHELL_TOP}/lib/argparsing.sh"

  __initialize "__initialize_base_setup"
}

__load()
{
  type "$1" 2>/dev/null | \grep -q 'is a function'
  typeset RC=$?
  # shellcheck source=/dev/null
  [ "${RC}" -ne 0 ] && . "$2"
}

__prepared()
{
  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && show_loaded "$( printf "%s" "$1" | \sed -e 's#^__prepared_##' )"
  typeset RC=$?
  [ "${RC}" -eq "${YES}" ] && return "${PASS}"
  return "${FAIL}"
}

__prepared_base_setup()
{
  __prepared "__prepared_base_setup"
}

__range_limit()
{
  if [ $# -lt 3 ]
  then
    printf "%s\n" "$1"
    return "${FAIL}"
  fi

  typeset current_value="$1"
  typeset lower_limit="$2"
  typeset upper_limit="$3"

  if [ -z "${lower_limit}" ] || [ -z "${upper_limit}" ]
  then
    printf "%s\n" "$1"
    return "${FAIL}"
  fi
  [ "${current_value}" -le "${lower_limit}" ] && current_value="${lower_limit}"
  [ "${current_value}" -ge "${upper_limit}" ] && current_value="${upper_limit}"

  printf "%s\n" "${current_value}"
  return "${PASS}"
}

__rest_in_sequence()
{
  typeset shift_count=$1
  shift_count=$(( shift_count + 1 ))
  shift ${shift_count}

  printf "%s " $@
  return "${PASS}"
}

__set2globals()
{
  (( $# < 2 )) && return "${FAIL}"
  typeset ___pattern_='^[_a-zA-Z][_0-9a-zA-Z]*$'
  [[ ! $1 =~ $___pattern_ ]] && return "${FAIL}"

  typeset __variable__name__=$1
  shift

  typeset ___v_
  typeset ___values_=()
  while (($# > 0))
  do
    ___v_=\'${1//"'"/"'\''"}\'
    ___values_=("${___values_[@]}" "$___v_") # push to array
    shift
  done

  eval $__variable__name__=\("${___values_[@]}"\)
  return "${PASS}"
}

__strip_quotes()
{
  [ -n "$1" ] && printf "%s\n" "$1" | \tr -d '"' | \tr -d "'"
  return "${PASS}"
}

__swap()
{
  typeset sep="${3:-:}"
  printf "%s\n" "$2${sep}$1"
  return "${PASS}"
}

__translate_rc()
{
  if [ -n "$1" ] && [ "$1" == '0' ]
  then
    printf "%d\n" "${YES}"
  else
    printf "%d\n" "${NO}"
  fi
  return "${PASS}"
}

__unix_prefix_trim()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"

  input=$( printf "%s\n" "${input}" | \tr -s ' ' | \sed -e 's#^ *##' )
  printf "%s\n" "${input}"
  return "${PASS}"
}

__unix_suffix_trim()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${FAIL}"

  input=$( printf "%s\n" "${input}" | \tr -s ' ' | \sed -e 's# *$##' )
  printf "%s\n" "${input}"
  return "${PASS}"
}

add_element()
{
  typeset id=1
  typeset separator=' '
  typeset format='%s'
  typeset new_data=

  OPTIND=1
  while getoptex "s: separator: id: d: data: new-data:" "$@"
  do
    case "${OPTOPT}" in
        'id'        ) id="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
        'new-data'  ) new_data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${FAIL}"
  if [ -z "${new_data}" ] || [ -z "${id}" ] || [ "${id}" -lt 1 ]
  then
    printf "${format}\n" "${data}"
    return "${FAIL}"
  fi

  typeset nextid=$(( id + 1 ))
  data=$( printf "${format}\n" "${data}" | \tr '\n' ' ' | \tr "${separator}" ' ' )
  typeset numelem=$( __get_word_count "${data}" )

  typeset front=
  typeset back=
  typeset result=
  if [ "${id}" -eq 1 ]
  then
    back="${data}"
    result="${new_data} ${back}"
  else
    front="${data}"
    nextid=$(( numelem + 1 ))
    if [ "${numelem}" -lt "${id}" ]
    then
      typeset cnt=$(( numelem + 1 ))
      while [ "${cnt}" -lt "${id}" ]
      do
        new_data="${separator}${new_data}"
        cnt=$(( cnt + 1 ))
      done
      result="${front}${new_data}"
    else
      nextid=$(( id - 1 ))
      front=$( printf "${format}\n" "${data}" | \cut -f 1-${nextid} -d ' ' )
      back=$( printf "${format}\n" "${data}" | \cut -f ${id}- -d ' ' )
      result="${front} ${new_data} ${back}"
    fi
  fi

  [ -n "${result}" ] && printf "${format}\n" "${result}" | \tr -s ' ' | \sed -e 's# $##' | \tr ' ' "${separator}"
  return "${PASS}"
}

add_trap_callback()
{
  typeset trap_cb="$1"
  typeset assoc_sig="$2"

  [ -z "${trap_cb}" ] && return
  [ -z "${assoc_sig}" ] && assoc_sig='EXIT'

  eval "SIG_${assoc_sig}_callbacks=\" \${SIG_${assoc_sig}_callbacks} ${trap_cb}\""
}

begin_initialized()
{
  typeset current_members
  current_members=$( printf "%s" "${REGISTRY}" | \sed -e "s#$1##g" )
  [ "x${current_members}" != "x${REGISTRY}" ] && return "${FAIL}"
  
  typeset name="${1#__initialize_}"
  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && printf "%s\n" "--> ${name} initializing..."
  return "${PASS}"
}

convert_pf_yn()
{
  [ -z "$1" ] || [ "$1" -ne "${PASS}" ] && printf "%d\n" "${NO}"
  [ -n "$1" ] && [ "$1" -eq "${PASS}" ] && printf "%d\n" "${YES}"
  return "${PASS}"
}

copy_file_segment()
{
  typeset filename=
  typeset beginline=
  typeset endline=
  typeset outputfile=

  OPTIND=1
  while getoptex "f: filename: b: beginline: e: endline: o: outputfile:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'   ) filename="${OPTARG}";;
    'b'|'beginline'  ) beginline="${OPTARG}";;
    'e'|'endline'    ) endline="${OPTARG}";;
    'o'|'outputfile' ) outputfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${FAIL}"
  typeset fileline_count=$( __get_line_count "${filename}" )

  [ "$( __get_word_count "${beginline}" )" -gt 1 ] || [ "$( __get_word_count "${endline}" )" -gt 1 ] && return "${FAIL}"
  [ -z "${beginline}" ] || [ "${beginline}" -lt 1 ] && beginline=1
  [ "${beginline}" -gt "${fileline_count}" ] && beginline="${fileline_count}"

  [ -z "${endline}" ] || [ "${endline}" -lt 1 ] && endline="${fileline_count}"

  if [ "${endline}" -lt "${beginline}" ]
  then
    typeset swapped_data="$( __swap "${beginline}" "${endline}" '|' )"
    beginline=$( get_element --data "${swapped_data}" --id 1 --separator '|' )
    endline=$( get_element --data "${swapped_data}" --id 2 --separator '|' )
  fi

  [ "${beginline}" -eq 0 ] || [ "${endline}" -eq 0 ] && return "${FAIL}"

  if [ -z "${outputfile}" ]
  then
    typeset segment="$( \sed -n "${beginline},${endline}p" "${filename}" )"
    printf "%s\n" "${segment}"
  else
    \sed -n "${beginline},${endline}p" "${filename}" > "${outputfile}"
  fi
  return "${PASS}"
}

default_value()
{  
  typeset default

  OPTIND=1
  while getoptex "d. def." "$@"
  do
    case "${OPTOPT}" in
    'd'|'def'  ) default="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset val="$1"
  shift

  [ -z "${default}" ] && [ -z "${val}" ] && return "${FAIL}"

  if [ -z "${val}" ]
  then
    printf "%s\n" "${default}"
  else
    printf "%s\n" "${val}"
  fi
  return "${PASS}"
}

dirs()
{
  printf "%s\n" ${__DIR_STACK}
  return "${PASS}"

#  printf "%s\n" "0: ${PWD}"
#  typeset sd=${#DIR_STACK[*]}
#  (( ind = 1 ))
#  while [ "${sd}" -gt 0 ]
#  do
#    printf "%s\n" "${ind}: ${DIR_STACK[sd]}"
#    (( sd = sd - 1 ))
#    (( ind = ind + 1 ))
#  done
}

end_initialized()
{
  typeset name="${1#__initialize_}"
  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && printf "%s\n" "--> ${name} initialized..."
  return "${PASS}"
}

end_timer()
{
  typeset timer_id="$1"
  [ -z "${timer_id}" ] && return "${FAIL}"

  typeset endtime=$( \date "+%s" )
  typeset var="SLCF_TIMER_${timer_id}"
  typeset dumpfile=
  
  [ -z "${SLCF_TEST_SUBSYSTEM_TEMPDIR}" ] && dumpfile="./${var}" || dumpfile="${SLCF_TEST_SUBSYSTEM_TEMPDIR}/${var}"
  printf "%s\n" "${endtime} - $( \tail -n 1 "${dumpfile}" )" | \bc
  [ -f "${dumpfile}" ] && \rm -f "${dumpfile}"
  return "${PASS}"
}

fn_exists()
{
  type "$1" 2>/dev/null | \grep -q 'is a function'
  typeset RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    printf "%d\n" "${YES}"
  else
    printf "%d\n" "${NO}"
  fi
}

generate_checksums()
{
  typeset filename=

  OPTIND=1
  while getoptex "f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'   ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${filename}" ] || [ ! -f "${filename}" ]
  then
    printf "%s\n" ':'
    return "${FAIL}"
  fi

  typeset md5val="$( \md5sum "${filename}" | \cut -f 1 -d ' ' )"
  typeset sha1val="$( \sha1sum "${filename}" | \cut -f 1 -d ' ' )"

  typeset chksums="${md5val}:${sha1val}"
  [ "${chksums}" == ':' ] && return "${FAIL}"

  printf "%s\n" "${chksums}"
  return "${PASS}"
}

get_bit_setting()
{
  typeset id=
  typeset data=

  OPTIND=1
  while getoptex "i: id: d: data:" "$@"
  do
    case "${OPTOPT}" in
        'id'    ) id="${OPTARG}";;
    'd'|'data'  ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${id}" ] || [ "${id}" -lt 1 ] && return "${FAIL}"

  [ "${id}" -gt ${#data} ] && return "${FAIL}"

  printf "%s\n" "${data}" | \cut -c "${id}"
  return "${PASS}"
}
 
get_element()
{
  typeset separator=' '
  typeset id=
  typeset format='%s'
  typeset data=

  OPTIND=1
  while getoptex "s: separator: id: d: data: f: format:" "$@"
  do
    case "${OPTOPT}" in
        'id'        ) id="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    'f'|'format'    ) format="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${id}" ] || [ "${id}" -lt 1 ] && return "${FAIL}"

  [ "${format}" != '%s' ] && [ "${format}" != '%b' ] && return "${FAIL}"

  ###
  ### Handle the separator if more than 1 character long...
  ###
  typeset sepsize=${#separator}

  data=$( printf "${format}\n" "${data}" | \tr '\n' ' ' )

  typeset result=
  if [ "${sepsize}" -gt 1 ]
  then
    data="$( printf "${format}\n" "${data}" | \sed -e "s#${separator}#|#g" )"
    separator='|'
  fi
  #  result="$( printf "${format}\n" "${data}" | \awk -F"${separator}" '$1=$1' | \cut -f ${id} -d ' ' )"
  #else
  result="$( printf "${format}\n" "${data}" | \cut -f ${id} -d "${separator}" )"
  #fi

  [ -n "${result}" ] && printf "${format}\n" "${result}" | \tr -s ' ' | \sed -e 's# $##'
  return "${PASS}"
}

get_function_names()
{
  #typeset fn="$1"
  typeset funcnames=$( typeset -f | \grep "()" | \grep -v "^ " | \sed -e 's#()##g' -e 's#{##g' | \grep -v "get_function_names" )
  #printf "%s " ${funcnames} > ./.function_names.txt
  #[ -n "${fn}" ] && funcnames=$( grep "()" "${fn}" | sed -e 's#[\(\)]##g' | cut -f 2 -d ' ' )
  #funcnames=$( grep -v "^${DECORATION_STRING}" ./.function_names.txt | grep -v "^__" )

  printf "%s " "${funcnames}"
  #rm -f ./function_names.txt
  return "${PASS}"
}

get_line_length()
{
  typeset line="$1"
  if [ -z "${line}" ]
  then
    printf "%d" 0
  else
    printf "%d" ${#line}
  fi
  return "${PASS}"
}

get_user_id()
{
  typeset userid="$( \whoami )"
  if [ -z "${userid}" ]
  then
    if [ -n "${USER}" ]
    then
      printf "%s\n" "${USER}"
    else
      if [ -n "${USERNAME}" ]
      then
        printf "%s\n" "${USERNAME}"
      else
        if [ -n "${LOGNAME}" ]
        then
          printf "%s\n" "${LOGNAME}"
        fi
      fi
    fi
  else
    printf "${userid}"
  fi
  return "${PASS}"
}

get_user_id_home()
{
  typeset userid
  userid=$( get_user_id )
  if [ -f '/etc/passwd' ]
  then
    typeset userid_home=
    userid_home=$( \cut -f 1,6 -d ':' /etc/passwd | \grep "^${userid}" | \cut -f 2 -d ':' )
    [ -z "${userid_home}" ] || [ ! -d "${userid_home}" ] && return "${NO}"
    printf "%s\n" "${userid_home}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

interpret_yn()
{
  if [ "$1" -eq "${NO}" ]
  then
    printf "%s\n" 'NO'
  else
    printf "%s\n" 'YES'
  fi
  return "${PASS}"
}

invert()
{
  if [ -z "$1" ] || [ "$1" -eq "${NO}" ]
  then
    printf "%s\n" "${YES}"
  else
    printf "%s\n" "${NO}"
  fi
  return "${PASS}"
}

is_false()
{
  case "$1" in
  [fF] | [nN] | [nN][oO] | [fF][aA][lL][sS][eE] ) printf "%d\n" "${YES}"; return "${PASS}";;
  esac
  printf "%d\n" "${NO}"
  return "${PASS}"
}

is_true()
{
  case "$1" in
  [tT] | [yY] | [yY][eE][sS] | [tT][rR][uU][eE] ) printf "%d\n" "${YES}"; return "${PASS}";;
  esac
  printf "%d\n" "${NO}"
  return "${PASS}"
}

next_in_sequence()
{
  typeset separator=' '
  typeset id=1

  OPTIND=1
  while getoptex "s: separator: id: d: data:" "$@"
  do
    case "${OPTOPT}" in
        'id'        ) id="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${FAIL}"
  [ -z "${id}" ] || [ "${id}" -lt 1 ] && return "${FAIL}"

  [ "x${separator}" != "x " ] && data=$( printf "%s\n" "${data}" | \sed -e "s#${separator}# #g" )
  typeset num_words="$( __unix_prefix_trim "$( printf "%s " "${data}" | \wc -w )" )"
  num_words="$( printf "%s\n" "${num_words}" | \cut -f 1 -d ' ' )"

  [ "${num_words}" -lt "${id}" ] && return "${FAIL}"

  typeset result=
  result="$( printf "%s" "${data}" | \cut -f ${id} -d ' ' )"
  printf "%s\n" "${result}"
  return "${PASS}"
}

pause()
{
  typeset msg=${1:-"Press [Enter] key to continue..."}
  
  [ -z "${AUTOMATED_TESTING}" ] && read -r -p "${msg}"
}

popd()
{
   __DIR_STACK=${__DIR_STACK#* }
   typeset top=${__DIR_STACK%% *}
   cd "${top}" || return "${FAIL}"
   printf "%s\n" "${PWD}"
   return "${PASS}"

#  typeset sd=${#DIR_STACK[*]}
#  if [ ${sd} -gt 0 ]
#  then
#    cd "${DIR_STACK[sd]}"
#    unset DIR_STACK[sd]
#  else
#    cd ~
#  fi
}

progress_bar()
{
  typeset current=
  typeset total=

  OPTIND=1
  while getoptex "c: current: t: total:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'current'   ) current="${OPTARG}";;
    't'|'total'     ) total="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${total}" ] && return "${FAIL}"
  [ -z "${current}" ] && current=0
  [ "${current}" -gt "${total}" ] && return "${PASS}"

  # Process data
  typeset _progress
  typeset _done
  typeset _left
  
  _progress=$(( (current * 100 / total * 100) / 100 ))
  _done=$(( _progress * 4 / 10 ))
  _left=$(( 40 - _done ))

  # Build progressbar string lengths
  typeset _fill
  typeset _empty

  _fill=$( printf "%${_done}s" )
  _empty=$( printf "%${_left}s" )
 
  # Build progressbar strings and print the ProgressBar line
  printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

pushd()
{
   typeset dir_name="$1"
   if [ -n "${dir_name}" ]
   then
     cd ${dir_name:?"missing directory name."} || return "${FAIL}"
     __DIR_STACK="${dir_name}|${__DIR_STACK:-$( \pwd -L )}"
     printf "%s\n" "${__DIR_STACK}"
   fi
   return "${PASS}"
#  typeset sd=${#DIR_STACK[*]}  # get total stack depth
#  if [ -n "${dir_name}" ]
#  then
#    if [ ${idir_name#\+[0-9]*} ]
#    then
#      # ======= "pushd dir" =======
#
#      # is "dir" reachable?
#      if [ `(cd "${dir_name}") 2>/dev/null; printf "%d\n" "$?"` -ne 0 ]
#      then
#        cd "${dir_name}"             # get the actual shell error message
#        return "${FAIL}              # return complaint status
#      fi
#
#      # yes, we can reach the new directory; continue
#
#      (( sd = sd + 1 ))      # stack gets one deeper
#      DIR_STACK[sd]="${PWD}"
#      cd "${dir_name}"
#      # check for duplicate stack entries
#      # current "top of stack" = ids; compare ids+dsdel to $PWD
#      # either "ids" or "dsdel" must increment with each loop
#      #
#      (( ids = 1 ))          # loop from bottom of stack up
#      (( dsdel = 0 ))        # no deleted entries yet
#      typeset sum=$(( ids + dsdel ))
#      while [ "${sum}" -le "${sd}" ]
#      do
#        if [ "${DIR_STACK[${sum}]}" == "${PWD}" ]
#        then
#          (( dsdel = dsdel + 1 ))  # logically remove duplicate
#        else
#          if [ "${dsdel}" -gt 0 ]
#          then        # copy down
#            DIR_STACK[${ids}]="${DIR_STACK[${sum}]}"
#          fi
#          (( ids = ids + 1 ))
#        fi
#        sum=$(( ids + dsdel ))
#      done
#
#      # delete any junk left at stack top (after deleting dups)
#
#      while [ "${ids}" -le "${sd}" ]
#      do
#        unset DIR_STACK["${ids}"]
#        (( ids = ids + 1 ))
#      done
#      unset ids
#      unset dsdel
#    else
#      # ======= "pushd +n" =======
#      (( sd = sd + 1 - ${dir_name#\+} ))    # Go 'n - 1' down from the stack top
#      if [ "${sd} -lt 1 ]
#      then
#        (( sd = 1 ))
#      fi
#       cd ${DIR_STACK[${sd}]}            # Swap stack top with +n position
#       DIR_STACK[${sd}]=${OLDPWD}
#    fi
#  else
#    #    ======= "pushd" =======
#    cd ${DIR_STACK[${sd}]}       # Swap stack top with +1 position
#    DIR_STACK[${sd}]=${OLDPWD}
#  fi
}

remove_element()
{
  typeset id=1
  typeset separator=' '
  typeset format='%s'

  OPTIND=1
  while getoptex "s: separator: id: d: data:" "$@"
  do
    case "${OPTOPT}" in
        'id'        ) id="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${FAIL}"
  if [ -z "${id}" ] || [ "${id}" -lt 1 ]
  then
    printf "${format}\n" "${data}"
    return "${FAIL}"
  fi

  typeset nextid=$(( id + 1 ))
  data=$( printf "${format}\n" "${data}" | \tr '\n' ' ' | \tr "${separator}" ' ' )
  typeset numelem=$( __get_word_count "${data}" )

  typeset front=
  typeset back=
  typeset result=
  if [ "${id}" -eq 1 ]
  then
    result="$( printf "${format}\n" "${data}" | \cut -f ${nextid}- -d ' ' )"
  else
    if [ "${numelem}" -lt "${id}" ]
    then
      result="${data}"
    else
      typeset previd="$(( id - 1 ))"
      front="$( printf "${format}\n" "${data}" | \cut -f 1-${previd} -d ' ' )"
      back="$( printf "${format}\n" "${data}" | \cut -f ${nextid}- -d ' ' )"
      result="${front} ${back}"
    fi
  fi

  [ -n "${result}" ] && printf "${format}\n" "${result}" | \tr -s ' ' | \sed -e 's# $##' | \tr ' ' "${separator}"
  return "${PASS}"
}

remove_color_coding()
{
  [ -z "$1" ] && return "${PASS}"
  printf "%s\n" "$1" | \sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
}

replace_element()
{
  remove_element $@
  add_element $@
}

rest_in_sequence()
{
  typeset data=
  typeset separator=' '
  typeset shifter=1

  OPTIND=1
  while getoptex "s: separator: shift: d. data." "$@"
  do
    case "${OPTOPT}" in
        'shift'     ) shifter="${OPTARG}";;
    's'|'separator' ) separator="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${data}" ] && return "${PASS}"
  [ -z "${shifter}" ] || [ "${shifter}" -lt 1 ] && return "${PASS}"

  [ "x${separator}" != "x " ] && data=$( printf "%s" "${data}" | \sed -e "s#${separator}# #g" )

  typeset result="$( __rest_in_sequence "${shifter}" "${data}" )"
  printf "%s\n" "${result}"
}

sleep_func()
{
  typeset sleep_value=1
  typeset old_style="${NO}"

  OPTIND=1
  while getoptex "s: old-version" "$@"
  do
    case "${OPTOPT}" in
    's'            ) sleep_value="${OPTARG}";;
    'old-version'  ) old_style="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "${old_style}" -eq "${NO}" ]
  then
    \which usleep > /dev/null 2>&1
    typeset RC=$?
    if [ "${RC}" -ne "${FAIL}" ]
    then
      usleep "${sleep_value}"
    else
      \sleep "$( printf "%s\n" "${sleep_value}/100000" | \bc )"
    fi
  else
    \sleep "${sleep_value}"
  fi

  return "${PASS}"
}

show_loaded()
{
  typeset current_members
  [ -z "$1" ] && return "${FAIL}"

  current_members=$( printf "%s" "${REGISTRY}" | \sed -e "s/ $1 //g" )
  [ "x${current_members}" == "x${REGISTRY}" ] && return "${FAIL}"

  typeset name="${1#__prepared_}"
  [ -n "${DEBUGGING}" ] && [ "${DEBUGGING}" != "0" ] && printf "%s\n" "<-- ${name} loaded..."
  return "${PASS}"
}

spinner()
{
  typeset sleep_value=500000
  typeset pid=
  typeset counter=8

  OPTIND=1
  while getoptex "s: p. pid. c. counter." "$@"
  do
    case "${OPTOPT}" in
    's'            ) sleep_value="${OPTARG}";;
    'p'|'pid'      ) pid="${OPTARG}";;
    'c'|'counter'  ) counter="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset spinstr='|/-\'
  if [ -z "${pid}" ]
  then
    typeset loop=
    for loop in $( \seq 1 ${counter} )
    do
      typeset temp="${spinstr#?}"
      printf "[%c]  " "$spinstr"
      typeset spinstr="$temp${spinstr%"$temp"}"
      sleep_func -s "${sleep_value}"
      printf "\b\b\b\b\b\b"
    done
  else
    while [ "$( \ps a | \awk '{print $1}' | \grep ${pid} )" ]
    do
      typeset temp="${spinstr#?}"
      printf "[%c]  " "$spinstr"
      typeset spinstr="$temp${spinstr%"$temp"}"
      sleep_func -s "${sleep_value}"
      printf "\b\b\b\b\b\b"
    done
  fi
  printf "    \b\b\b\b"
}

sprintf()
{
  typeset stdin=
  read -r -d '' -u 0 stdin
  printf "$@" "${stdin}"
}

start_timer()
{
  typeset timer_id="$1"
  [ -z "${timer_id}" ] && return "${FAIL}"

  typeset var="SLCF_TIMER_${timer_id}"
  typeset dumpfile=
  
  if [ -z "${SLCF_TEST_SUBSYSTEM_TEMPDIR}" ]
  then
    dumpfile="./${var}"
  else
    dumpfile="${SLCF_TEST_SUBSYSTEM_TEMPDIR}/${var}"
  fi
  printf "%s\n" "$( \date "+%s" )" >> "${dumpfile}"
  return "${PASS}"
}

timer()
{
  typeset uniqdate=$( \date "+%s" )
  { time { "${@:4}" ; } 2>${_} {_}>&- ; } {_}>&2 2>"/tmp/$$.${uniqdate}"
  set -- $? "$@"
  read -r -d "" _ "$2" _ "$3" _ "$4" _ < "/tmp/$$.${uniqdate}"
  \rm -f "/tmp/$$.${uniqdate}"
  return $1
}

# ---------------------------------------------------------------------------
__initialize_base_setup
__prepared_base_setup
