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
## @Software Package : Shell Automated Testing -- File Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.21
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    change_dir
#    change_file_extension
#    collect_files
#    convert_pattern
#    define_semaphore_file
#    find_if_file_or_dir_exists
#    find_in_file
#    find_match_in_file
#    find_match_in_line
#    find_matching_line_in_file
#    get_comment_char
#    get_file_line_length
#    get_verbosity_info
#    is_comment
#    make_error_filename
#    make_lockfile
#    remove_characters
#    replace_line_in_file
#    set_comment_char
#    set_semaphore
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117,SC2068,SC2086,SC2154,SC2181

[ -z "${__COMMENT_CHAR}" ] && __COMMENT_CHAR='#'

__initialize_filemgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -e "$( \dirname '$0' )" )

  __load __initialize_machinemgt "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  __load __initialize_execaching "${SLCF_SHELL_TOP}/lib/execaching.sh"

  typeset extensions='semaphore logfile mail error text resource'
  typeset ext=
  for ext in ${extensions}
  do
    typeset matching_line="$( \grep "${ext}_extension:" "${SLCF_SHELL_TOP}/resources/common/global_settings.rc" )"
    [ $? -eq "${PASS}" ] && eval "${ext}_extension=$( printf "%s\n" "${matching_line}" | \cut -f 2 -d ':' )"
  done

  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/file_assertions.sh"

  __initialize "__initialize_filemgt"
}

__prepared_filemgt()
{
  __prepared "__prepared_filemgt"
}

# Should either use pushd/popd or use an internal means to determine
# next directory and previous directory (a stack).  Fix the base_setup pushd and popd
# to remove this function from this library
change_dir()
{
  __debug $@

  typeset RC="${FAIL}" 
  pushd "$1" || return "${RC}"
  RC=$?
  [ "${RC}" -eq "${PASS}" ] && __debug "Changed directory to <$1>"
  return "${RC}"
}

change_file_extension()
{
  __debug $@
  
  typeset filename=
  typeset extension=
  
  OPTIND=1
  while getoptex "f: file: e: extension:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'      ) filename="${OPTARG}";;
    'e'|'extension' ) extension="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset current_ext="${filename#*.}"

  if [ "${current_ext}" == "${filename}" ]
  then
    filename+=".${extension}"
  else
    filename="${filename/%.${current_ext}/.${extension}}"
  fi
  print_plain --message "${filename}"
  return "${PASS}"
}

collect_files()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  make_executable --exe 'find' "-s -p/usr/bin"
  RC=$?
  #__handle_missing_executable ${RC} "find" "collect_files"
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset path="."
  typeset pattern='*'
  typeset outputfile=
  typeset retain_file=${NO}

  OPTIND=1
  while getoptex "f: outfile: k keepfile p: path: t: pattern:" "$@"
  do
    case "${OPTOPT}" in
    'k'|'keepfile' )    retain_file=${YES};;
    'p'|'path'     )    path="${OPTARG}";;
    't'|'pattern'  )    pattern="${OPTARG}";;
    'f'|'outfile'  )    [ -f "${outputfile}" ] && \rm -f "${outputfile}"; outputfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${outputfile}" )" -eq "${YES}" ] && outputfile="$( make_temp_file )"
  [ "$( is_empty --str "${outputfile}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset found_files=
  ${find_exe} "${path}" -name "${pattern}" -print > "${outputfile}" 2>/dev/null

  found_files="$( \cat "${outputfile}" )"
  [ "$( is_empty --str "${found_files}" )" -eq "${NO}" ] && printf "%s " ${found_files}
  [ "${retain_file}" -eq "${NO}" ] && [ -f "${outputfile}" ] && \rm -f "${outputfile}"
  return "${PASS}"
}

convert_pattern()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset from_pattern=
  typeset to_pattern=
  typeset filename=
  typeset backup=${NO}
  typeset global=

  OPTIND=1
  while getoptex "f. file. old-patt: new-patt: b backup g global" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'     )    filename="${OPTARG}";;
        'old-patt' )    from_pattern="${OPTARG}";;
        'new-patt' )    to_pattern="${OPTARG}";;
    'b'|'backup'   )    backup=${YES};;
    'g'|'global'   )    global='g';;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] && return "${FAIL}"
  [ "$( is_empty --str "${from_pattern}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset tmpfile="$( make_temp_file --directory "$( get_temp_dir)" --file "${filename}.tmp" )"
  \sed -e "s#${from_pattern}#${to_pattern}#${global}" "${filename}" > "${tmpfile}"

  if [ ! -f "${tmpfile}" ]
  then
    print_plain --message "Unable to update << ${filename} >>!"
    return "${FAIL}"
  fi
  
  [ "$( is_empty --str "${backup}" )" -eq "${NO}" ] && [ "${backup}" -eq "${YES}" ] && \cp -f "${filename}" "${filename}.bak"
  \mv -f "${tmpfile}" "${filename}" > /dev/null 2>&1
  \rm -f "${tmpfile}"
  return $?
}

define_semaphore_file()
{
  __debug $@
  
  typeset semaphore_type=

  OPTIND=1
  while getoptex "s: semtype: t. tag." "$@"
  do
    case "${OPTOPT}" in
    's'|'semtype' ) semaphore_type="${OPTARG}";;
    't'|'tag'     ) tag="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${semaphore_type}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset semaphore_file=
  if [ "$( is_empty --str "${tag}" )" -eq "${YES}" ]
  then
    semaphore_file="${semaphore_type}.${semaphore_extension}"
  else
    semaphore_file="${semaphore_type}_${tag}.${semaphore_extension}"
  fi
  
  print_plain --message "${semaphore_file}"
  return "${PASS}"
}

find_if_file_or_dir_exists()
{
  __debug $@
  
  typeset user=
  typeset machineip=
  
  OPTIND=1
  while getoptex "u. user. m: machineip: machine: f. file. d. directory. dir." "$@"
  do
    case "${OPTOPT}" in
    'u'|'user'                       ) user="${OPTARG}";;
    'm'|'machine'|'machineip'        ) machineip="${OPTARG}";;
    'f'|'file'|'d'|'dir'|'directory' ) file_directory="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${file_directory}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset result="${FAIL}"
  typeset is_local="${NO}"

  if [ "$( is_empty --str "${user}" )" -eq "${YES}" ]
  then
    if [ "$( is_empty --str "${machineip}" )" -eq "${YES}" ]
    then
      is_local="${YES}"
    else
      user=$( get_user_id )
    fi
  fi

  typeset RC
  if [ "${is_local}" -eq "${YES}" ]
  then
    [ -f "${file_directory}" ] || [ -d "${file_directory}" ] && RC="${PASS}"
  else
    typeset output="$( \ssh ${user}@${machineip} "if [ -f \"${file_directory}\" ] && [ -d \"${file_directory}\" ]; then printf \"%d\" \$? > .xyz; cat .xyz; rm -f .xyz; fi" > /dev/null 2>&1 )"
    RC=$?
  fi
  return "${RC}"
}

find_in_file()
{
  __debug $@
  
  typeset filename=
  typeset text=

  OPTIND=1
  while getoptex "d: data: f: file:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) text="${OPTARG}";;
    'f'|'file' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${text}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ -f "${filename}" ]
  then
    \grep -q "^${text}$" "${filename}"
    return $?
  fi
  return "${FAIL}"
}

find_match_in_file()
{
  __debug $@
  
  typeset filename=
  typeset regex_pattern=
  typeset grep_flags=

  OPTIND=1
  while getoptex "p: pattern: f: file: g. grep-options." "$@"
  do
    case "${OPTOPT}" in
    'p'|'pattern'      ) regex_pattern="${OPTARG}";;
    'f'|'file'         ) filename="${OPTARG}";;
    'g'|'grep-options' ) grep_flags+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}" 
  if [ -f "${filename}" ]
  then
    [ "$( is_empty --str "${regex_pattern}" )" -eq "${YES}" ] && return "${PASS}"

    typeset result=$( \grep ${grep_flags} "${regex_pattern}" "${filename}" )
    if [ "$( is_empty --str "${result}" )" -eq "${NO}" ]
    then
      print_plain --message "${result}"
      return "${PASS}"
    fi
  else
    return "${FAIL}"
  fi

  return "${FAIL}"
}

find_matching_line_in_file()
{
  __debug $@

  typeset filename=
  typeset regex_pattern=
  typeset grep_flags='-n'

  OPTIND=1
  while getoptex "p: pattern: f: file: g. grep-options." "$@"
  do
    case "${OPTOPT}" in
    'p'|'pattern'      )    regex_pattern="${OPTARG}";;
    'f'|'file'         )    filename="${OPTARG}";;
    'g'|'grep-options' )    grep_flags+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
 
  if [ ! -f "${filename}" ]
  then
    print_plain --message "0" --format "%d"
    return "${FAIL}"
  fi

  if [ "$( is_empty --str "${regex_pattern}" )" -eq "${YES}" ]
  then
    print_plain --message '0' --format "%d"
    return "${PASS}"
  fi

  typeset result="$( \grep ${grep_flags} "${regex_pattern}" "${filename}" | \cut -f 1 -d ':' | \tr '\n' ' ' )"
  if [ "$( is_empty --str "${result}" )" -eq "${YES}" ]
  then
    print_plain --message '0' --format "%d"
    return "${FAIL}"
  else
    typeset count="$( __get_word_count "${result}" )"
    print_plain --message "${count}" --format "%d"
    return "${PASS}"
  fi
}

find_match_in_line()
{
  __debug $@

  typeset entryline=
  typeset regex_pattern=
  typeset grep_flags=

  OPTIND=1
  while getoptex "p. pattern. l. line. g: grep-options:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pattern'      ) regex_pattern="${OPTARG}";;
    'l'|'line'         ) entryline="${OPTARG}";;
    'g'|'grep-options' ) grep_flags="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  if [ "$( is_empty --str "${entryline}" )" -eq "${YES}" ] || [ "$( is_empty --str "${regex_pattern}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi

  typeset result="$( printf "%s\n" "${entryline}" | \grep ${grep_flags} "${regex_pattern}" )"
  if [ "$( is_empty --str "${result}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  else
    print_plain --message "${YES}"
    return "${PASS}"
  fi
}

get_comment_char()
{
  printf "%s\n" "${__COMMENT_CHAR}"
  return "${PASS}"
}

get_file_line_length()
{
  __debug $@
  
  typeset file=$1
 
  if [ "$( is_empty --str "${file}" )" -eq "${YES}" ] || [ ! -f "${file}" ]
  then
    print_plain --message "0" --format "%d"
    return "${FAIL}"
  fi
  
  typeset data="$( __get_line_count "${file}" )"
  print_plain --message "${data}" --format "%d"
  return "${PASS}"
}

get_verbosity_info()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset extrainfo=
  typeset verbose="${VERBOSITY_LEVEL:-0}"
  
  OPTIND=1
  while getoptex "v. verbose." "$@"
  do
    case "${OPTOPT}" in
    'v'|'verbose' ) verbose=$(( verbose + 1 ));;
    esac
  done
  shift $(( OPTIND-1 ))

  verbose="$( __range_limit ${verbose} 0 2 )"

  [ "$( is_empty --str "${verbose}" )" -eq "${YES}" ] && verbose=0
  if [ "${verbose}" -eq 1 ]
  then
    extrainfo="$( \date "+%Y/%m/%d" )"
  elif [ "${verbose}" -gt 1 ]
  then
    extrainfo="PID:$$ -- "$( \date "+%Y/%m/%d :: %H:%M:%S" )
    extrainfo+=" | $( get_user_id )"
  fi

  [ -n "${extrainfo}" ] && print_plain --message "${extrainfo}"
  return "${PASS}"
}

is_comment()
{
  __debug $@

  typeset str=
  typeset cmtchar="$( get_comment_char )"

  OPTIND=1
  while getoptex "s: str: c. comment-char." "$@"
  do
    case "${OPTOPT}" in
    's'|'str'          ) str="${OPTARG}";;
    'c'|'comment-char' ) cmtchar="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${str}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
  else
    typeset cclen="${#cmtchar}"
    typeset firstchars="${str:0:${cclen}}"
    if [ "x${firstchars}" == "x${cmtchar}" ]
    then
      print_plain --message "${YES}"
    else
      print_plain --message "${NO}"
    fi
  fi
  return "${PASS}"
}

make_error_filename()
{
  __debug $@
  
  typeset func_name=
  #[ "$( is_empty --str "${SCRIPT_PATH}" )" -eq "${YES}" ] && get_script_path > /dev/null 2>&1

  typeset userid=$( get_user_id )
  typeset host=$( \hostname )
  typeset path="$( get_temp_dir )/error_handling"

  OPTIND=1
  while getoptex "f: func-name: p: path:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'func-name' ) func_name="${OPTARG}";;
    'p'|'path'      ) path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${func_name}" )" -eq "${YES}" ] && func_name="UNKNOWN"
  
  print_plain --message "${path}/$$_${func_name}_${userid}_${host}_eh.${error_extension}"
  return "${PASS}"
}

make_lockfile()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  #[ $( is_empty --str "${SCRIPT_PATH}" ) -eq "${YES}" ] && get_script_path > /dev/null 2>&1

  typeset directory="$( get_temp_dir )"
  typeset lockfilename=".lockfile"
  typeset permissions=777
  typeset msg=$$
  typeset return_lockfilename="${NO}"
  typeset skip_creation="${NO}"

  OPTIND=1
  while getoptex "d: directory: f: lock-file: m: msg: p. permissions. r s" "$@"
  do
    case "${OPTOPT}" in
    'd'|'directory'   ) directory="${OPTARG}";;
    'f'|'lock-file'   ) lockfilename="${OPTARG}";;
    'm'|'msg'         ) msg="${OPTARG}";;
    'p'|'permissions' ) permissions="${OPTARG}";;
    'r'               ) return_lockfilename="${YES}";;
    's'               ) skip_creation="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "${skip_creation}" -eq "${NO}" ]
  then
    [ ! -d "${directory}" ] && \mkdir -p "${directory}"
    print_plain --message "${msg}" > "${directory}/${lockfilename}";
    \chmod -R "${permissions}" "${directory}"
  fi

  [ "${return_lockfilename}" -eq "${YES}" ] && print_plain --message "${directory}/${lockfilename}"
  return "${PASS}"
}

remove_characters()
{
  __debug $@
  
  typeset str=
  typeset numchars=1
  
  OPTIND=1
  while getoptex "s. str. n. num-char." "$@"
  do
    case "${OPTOPT}" in
    's'|'str'      ) str="${OPTARG}";;
    'n'|'num-char' ) numchars="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${str}" ] && return "${FAIL}"
  [ "${numchars}" -lt 0 ] && return "${FAIL}"

  typeset pathlen="${#str}"

  (( pathlen = pathlen - numchars ))
  [ "${pathlen}" -lt 0 ] && pathlen=0
  typeset result="${str:0:${pathlen}}"

  [ "$( is_empty --str "${result}" )" -eq "${NO}" ] && print_plain --message "${result}"
  return "${PASS}"
}

replace_line_in_file()
{
  __debug $@

  typeset pattern=
  typeset replacement=
  typeset filename=
  typeset line_id=0

  OPTIND=1
  while getoptex "p: pattern: r: replacement: f: file: l: line-id:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pattern'     ) pattern="${OPTARG}";;
    'r'|'replacement' ) replacement="${OPTARG}";;
    'f'|'file'        ) filename="${OPTARG}";;
    'l'|'line-id'     ) line_id="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ ! -f "${filename}" ] || [ "$( is_empty --str "${pattern}" )" -eq "${YES}" ] || [ "$( is_empty --str "${replacement}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ "${line_id}" -lt 1 ]
  then
    typeset line=
    typeset final=
    typeset RC=${PASS}
    while read -u 9 -r line
    do
      printf "%s\n" "${line}" | \grep -q "${pattern}" >/dev/null 2>&1
      RC=$?
	
      if [ "${RC}" -eq "${PASS}" ]
      then
        final="${final}\n${replacement}"
      else
        final="${final}\n${line}"
      fi
    done 9< "${filename}"

    print_plain --message "${final}" > "${filename}"
  else
    tmpfile="$( make_temp_file )"
    [ -z "${tmpfile}" ] && return "${FAIL}"
    \sed -n "${line_id}p" "${filename}" > "${tmpfile}"
    [ -f "${filename}" ] && [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${filename}"
  fi
  return "${PASS}"
}

set_comment_char()
{
  typeset cc="$1"
  [ -z "${cc}" ] && return "${FAIL}"
  __COMMENT_CHAR="${cc}"
  return "${PASS}"
}

set_semaphore()
{
  __debug $@
  
  typeset directory=
  typeset semaphore_type=
  typeset tag=
  
  OPTIND=1
  while getoptex "d: directory: s: semtype: t: tag:" "$@"
  do
    case "${OPTOPT}" in
    't'|'tag'       )     tag="${OPTARG}";;
    'd'|'directory' )     directory="${OPTARG}";;
    's'|'semtype'   )     semaphore_type="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${directory}" )" -eq "${YES}" ] || [ ! -d "$directory" ] && return "${FAIL}"

  [ "$( is_empty --str "${tag}" )" -eq "${NO}" ] && dsf_options+=" --tag ${tag}"

  typeset semaphore_file="$( define_semaphore_file --semtype "${semaphore_type}" ${dsf_options} )"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  semaphore_file="${directory}/${semaphore_file}"
  #semaphore_file=$( convert_path_for_machine --path "${directory}/${semaphore_file}" )

  [ -f "${semaphore_file}" ] && \rm -f "${semaphore_file}"
  touch "${semaphore_file}"
  return "${PASS}"
}

snap_directory_listing()
{
  typeset listing_location=
  typeset style=
  typeset output=

  OPTIND=1
  while getoptex "d: directory: o: output-file: s: style:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'output-file' )  output="${OPTARG}";;
    'd'|'directory'   )  listing_location="${OPTARG}";;
    's'|'style'       )  style="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
 
  [ "$( is_empty --str "${listing_location}" )" -eq "${YES}" ] || [ "$( is_empty --str "${style}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${output}" )" -eq "${YES}" ] && output="$( make_output_file --channel 'DIRLIST' )"
  
  typeset listing="$( \ls -1 | \grep -v __directory_contents )"
  if [ -z "${output}" ]
  then
    printf "%s\n" "${listing}"
  else
    printf "%s\n" "${listing}" > "${output}"
    printf "%s\n" "${output}"
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/execaching.sh"
fi

__initialize_filemgt
__prepared_filemgt
