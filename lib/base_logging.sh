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
## @Software Package : Shell Automated Testing -- Base Logging
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.77
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __assign_filemgr
#    __cleanup_filemgr
#    __get_repeat_char
#    __set_repeat_char
#    append_output
#    append_output_tee
#    associate_file_to_channel
#    center_text
#    copy_output_file
#    discard
#    display_all_stored_files
#    display_stored_file
#    find_output_channel
#    find_output_file
#    get_all_output_channels
#    get_all_output_files
#    get_latest_generated_output_channel
#    get_latest_generated_output_file
#    get_latest_output_channel
#    get_latest_output_file
#    get_all_persistent_channels
#    get_all_persistent_files
#    get_number_output_files
#    get_number_persistent_files
#    is_channel_in_use
#    is_channel_persistent
#    make_next_available_channel_for_file
#    make_output_file
#    make_unique_channel_name
#    mark_channel_persistent
#    register_tmpfile
#    remove_channel
#    remove_all_output_files
#    remove_output_file
#    reset_output_file
#    store_output
#
###############################################################################

# shellcheck disable=SC2068,SC2039,SC1117,SC2119,SC2016,SC2086,SC2034

if [ -z "${__FILEMGRFILE}" ]
then
  __FILEMGRFILE=
  __FILEMARKER='FT_'
  __CURRENT_FILE=
  __TEMP_PATTERN='XXXXXX'  # Solaris only uses the first six template chars
  __STD_REPEAT_CHAR='='
fi

__assign_filemgr()
{
  __debug $@

  typeset newfilemgr=

  OPTIND=1
  while getoptex "f: filemgr:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filemgr'   ) newfilemgr="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${newfilemgr}" )" -eq "${YES}" ] || [ ! -f "${newfilemgr}" ] && return "${FAIL}"
  __FILEMGRFILE="${newfilemgr}"
}

__cleanup_filemgr()
{
  __debug $@

  typeset RC="${PASS}"
  typeset clearmaster="${NO}"
  typeset display="${NO}"

  OPTIND=1
  while getoptex "c clear-all d display-files" "$@"
  do
    case "${OPTOPT}" in
    'c'|'clear-all'      ) clearmaster="${YES}";;
    'd'|'display-files'  ) display="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${display}" -eq "${YES}" ] && display_all_stored_files

  remove_all_output_files

  [ -n "${__CURRENT_FILE}" ] && [ -f "${__CURRENT_FILE}" ] && \rm -f "${__CURRENT_FILE}"

  if [ -n "${__FILEMGRFILE}" ] && [ -f "${__FILEMGRFILE}" ]
  then
    if [ ! -s "${__FILEMGRFILE}" ]
    then
      \rm -f "${__FILEMGRFILE}"
      RC=$?
    else
      if [ "${clearmaster}" -eq "${YES}" ]
      then
        \rm -f "${__FILEMGRFILE}"
        RC=$?
      fi
    fi
  fi
  return "${RC}"
}

__get_repeat_char()
{
  __debug $@

  printf "%s\n" "${__STD_REPEAT_CHAR}"
  return "${PASS}"
}

__initialize_base_logging()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )
  
  __load __initialize_timemgt "${SLCF_SHELL_TOP}/lib/timemgt.sh"
  
  typeset today=
  if [ -n "${__START_TIME}" ]
  then
    today="${__START_TIME}"
  else
    today=$( __today_as_seconds )
  fi

  if [ -z "${__FILEMGRFILE}" ]
  then
    typeset possible_tmpdirs='TEMPORARY_DIR TEMP TMP TEMPDIR TMPDIR'  # THIS IS A HACK FOR FREEBSD/OPENBSD 'mktemp'
    typeset SUBSFILEMGRFILE="$( \mktemp "$( get_user_id )_${today}_filemgrfile.${__TEMP_PATTERN}" )"
    typeset ptd=
    typeset pt=
    for ptd in ${possible_tmpdirs}
    do
      eval "pt=\${${ptd}}"
      if [ -d "${pt}" ]
      then
        case ${pt} in
          *[!/]*/) pt=${pt%"${pt##*[!/]}"};;
        esac
        __FILEMGRFILE="${pt}/${SUBSFILEMGRFILE}"
        \mv -f "${SUBSFILEMGRFILE}" "${__FILEMGRFILE}"
        break
      fi
    done
  fi
  __CURRENT_FILE=

  add_trap_callback __cleanup_filemgr EXIT

  \which 'tput' >/dev/null 2>&1
  typeset RC=$?
  [ "${RC}" -eq "${PASS}" ] && COLUMNS=$( \tput cols ) || COLUMNS=80

  __initialize '__initialize_base_logging'
}

__prepared_base_logging()
{
  __prepared '__prepared_base_logging'
}

__set_repeat_char()
{
  [ -n "$1" ] && __STD_REPEAT_CHAR="$1"
  return "${PASS}"
}

append_output()
{
  __debug $@

  typeset data=
  typeset channel=
  typeset marker=
  typeset raw="${NO}"
  
  OPTIND=1
  while getoptex "d: data: c: channel: r raw m: marker:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    'd'|'data'      ) data="${OPTARG}";;
    'm'|'marker'    ) marker="${OPTARG}";;
    'r'|'raw'       ) raw="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${data}" )" -eq "${YES}" ] && return "${PASS}"

  typeset latest_file
  
  if [ "$( is_empty --str "${channel}" )" -eq "${YES}" ]
  then
    latest_file="$( get_latest_output_file )"
    [ "$( is_empty --str "${latest_file}" )" -eq "${YES}" ] && latest_file="$( make_output_file )"
    channel=$( find_output_channel --file "${latest_file}" )
  else
    if [ "$( to_upper "${channel}" )" != 'STDOUT' ]
    then
      latest_file="$( find_output_file --channel "${channel}" )"	
      [ "$( is_empty --str "${latest_file}" )" -eq "${YES}" ] && latest_file="$( make_output_file --channel "${channel}" )"
    fi
  fi
  
  if [ "$( to_upper "${channel}" )" == 'STDOUT' ]
  then
    typeset insertion=
    [ -n "${marker}" ] && insertion="[ ${marker} ]"

    typeset maxlines=$( printf "%s\n" "${data}" | \wc -l )
    if [ "${maxlines}" -gt 1 ]
    then
      typeset curr_l=1
      while [ "${curr_l}" -lt "${maxlines}" ]
      do
        typeset subdata="$( printf "%s\n" "${data}" | \sed -n "${curr_l},${curr_l}p" )"
        if [ -z "${insertion}" ]
        then
          print_plain --message "${subdata}" --format "%s\n"
        else
          print_plain --message "${insertion} ${subdata}" --format "%s\n"
        fi
        curr_l=$(( curr_l + 1 ))
      done
    else
      if [ -z "${insertion}" ]
      then
        print_plain --message "${data}" --format "%s\n"
      else
        print_plain --message "${insertion} ${data}" --format "%s\n"
      fi
    fi
  else
    if [ "${raw}" -eq "${NO}" ]
    then
      typeset insertion=
      if [ -n "${marker}" ]
      then
        insertion="${marker}"
      else
        insertion="${channel}"
      fi

      typeset maxlines=$( printf "%s\n" "${data}" | \wc -l )
      if [ "${maxlines}" -gt 1 ]
      then
        typeset curr_l=1
        while [ "${curr_l}" -lt "${maxlines}" ]
        do
          typeset subdata="$( printf "%s\n" "${data}" | \sed -n "${curr_l},${curr_l}p" )"
          print_plain --message "[ ${insertion} ] ${subdata}" --format "%s\n" >> "${latest_file}"
          curr_l=$(( curr_l + 1 ))
        done
      else
        print_plain --message "[ ${insertion} ] ${data}" --format "%s\n" >> "${latest_file}"
      fi
    else
      print_plain --message "${data}" --format "%s\n" >> "${latest_file}"
    fi
  fi
  return "${PASS}"
}

append_output_tee()
{
  __debug $@

  typeset data=
  typeset channels=
  typeset raw="${NO}"
  typeset substitution=
  typeset marker=

  typeset OAA=${OPTALLOW_ALL}
  OPTALLOW_ALL="${YES}"

  OPTIND=1
  while getoptex "d: data: c: channel: raw s: substitution: m: marker:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'       ) channels+=" ${OPTARG}";;
    'd'|'data'          ) data="${OPTARG}";;
        'raw'           ) raw="${YES}";;
    's'|'substitution'  ) substitution="${OPTARG}";;
    'm'|'marker'        ) marker="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  OPTALLOW_ALL=${OAA}

  # Speciality Channels
  # 1) ERROR
  
  [ "$( is_empty --str "${data}" )" -eq "${YES}" ] && return "${PASS}"

  typeset opts=
  [ "${raw}" -eq "${YES}" ] && opts+=' --raw'

  [ -n "${substitution}" ] && data="$( printf "%s\n" "${data}" | \sed ":a;\$!ba;s/${substitution}/\\n/g" )"
  
  typeset channel=
  for channel in ${channels}
  do
    #[ $( is_empty --str "${channel}" ) -eq "${YES}" ] && continue

    typeset cap_channel=$( to_upper "${channel}" )
    if [ "${cap_channel}" == 'ERROR' ]
    then
      print_plain --message "[ ERROR ] ${data}" --format "%s\n"
      append_output --data "${data}" --channel 'ERROR' --marker 'ERROR' ${opts} $@
    else
      if [ -n "${marker}" ]
      then
        append_output --data "${data}" --channel "${channel}" --marker "${marker}" ${opts} $@
      else
        append_output --data "${data}" --channel "${channel}" ${opts} $@
      fi
    fi
  done
  return "${PASS}"
}

associate_file_to_channel()
{
  __debug $@

  typeset channel=
  typeset filename=
  typeset ignore_file_exist="${NO}"
  typeset persist=
  typeset access=
  
  OPTIND=1
  while getoptex "c: channel: f: file: i ignore-file-existence p persist a: access:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'                   ) filename="${OPTARG}";;
    'c'|'channel'                ) channel="${OPTARG}";;
    'a'|'access'                 ) access="${OPTARG}";;
    'i'|'ignore-file-existence'  ) ignore_file_exist="${YES}";;
    'p'|'persist'                ) persist="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_channel_in_use --channel "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  
  [ "${ignore_file_exist}" -eq "${NO}" ] && [ ! -f "${filename}" ] && return "${FAIL}"
  
  [ -n "${persist}" ] && persist=$( __range_limit "${persist}" "${NO}" "${YES}" )
  if [ -n "${persist}" ] && [ "${persist}" -eq "${YES}" ]
  then
    print_plain --msg "${channel}:${filename}:${persist}" >> "${__FILEMGRFILE}"
  else
    print_plain --msg "${channel}:${filename}" >> "${__FILEMGRFILE}"
  fi

  if [ -n "${access}" ]
  then
    [ ! -f "${filename}" ] && \touch "${filename}"
    \chmod ${access} "${filename}"
  fi
  return "${PASS}"
}

center_text()
{
  __debug $@
  typeset c_text=
  typeset c_width=${COLUMNS}

  OPTIND=1
  while getoptex "t: text: w: width:" "$@"
  do
    case "${OPTOPT}" in
    't'|'text'  )    c_text="${OPTARG}";;
    'w'|'width' )    c_width="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${c_text}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ ${#c_text} -gt "${c_width}" ]
  then
    c_width=${#c_text}
    [ "${c_width}" -gt "${COLUMNS}" ] && c_width="${COLUMNS}"
  fi
  c_width=$(( ( c_width + ${#c_text} ) / 2 ))
  print_plain --format "%${c_width}.${c_width}s\n" --message "${c_text}"
  return "${PASS}"
}

copy_output_file()
{
  __debug $@
  typeset channel=
  typeset target_file=
  
  OPTIND=1
  while getoptex "c: channel: f: file:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    'f'|'file'      ) target_file="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${target_file}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset filename=$( find_output_file --channel "${channel}" )
  
  if [ "$( is_empty --str "${filename}" )" -eq "${NO}" ]
  then
    typeset dn=$( \dirname "${target_file}" )
    [ ! -f "${dn}" ] && \mkdir -p "${dn}"
    \cp -f "${filename}" "${target_file}"
  fi
  return "${PASS}"
}

discard()
{
  __debug $@

  typeset discard_channel='__global_DISCARD'
  typeset keep_name="${NO}"
  
  OPTIND=1
  while getoptex "c: channel: u use-name" "$@"
  do
    case "${OPTOPT}" in
    'u'|'use-name'  ) keep_name="${YES}";;
    'c'|'channel'   ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${keep_name}" -eq "${NO}" ] && channel="__${channel}_DISCARD"
  
  typeset discardpile="$( find_output_file --channel "${channel}" )"

  [ "$( is_empty --str "${discardpile}" )" -eq "${YES}" ] && return "${PASS}"

  typeset line
  while read -u 9 -r line
  do
    [ -f "${line}" ] && \rm -f "${line}"
  done 9< "${discardpile}"

  remove_output_file --channel "${channel}"
  return $?
}

display_stored_file()
{
  __debug $@
  typeset channel=
  typeset filename=
  
  OPTIND=1
  while getoptex "c: channel: f: file:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    'f'|'file'      ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ]
  then
    filename=$( find_output_file --channel "${channel}" )
    [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  fi
  [ -f "${filename}" ] && \cat "${filename}"
  return "${PASS}" 
}

display_all_stored_files()
{
  typeset kf
  typeset __known_files="$( get_all_output_files )"
  for kf in ${__known_files}
  do
    typeset kft="$( get_element --data "${kf}" --id 1 --separator ':' )"
    typeset kfn="$( get_element --data "${kf}" --id 2 --separator ':' )"
    [ ! -f "${kfn}" ] && continue
    print_plain --message "++++> File : ${kfn} | Channel : ${kft}"
    \cat "${kfn}"
  done
  return "${PASS}"
}

find_output_channel()
{
  __debug $@
  typeset filename=
  
  OPTIND=1
  while getoptex "f: file:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'   ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ]
  then
    get_latest_output_channel
    return "${PASS}"
  fi

  typeset kf
  typeset __known_files="$( get_all_output_files )"
  for kf in ${__known_files}
  do
    typeset kft="$( get_element --data "${kf}" --id 1 --separator ':' )"
    typeset kfn="$( get_element --data "${kf}" --id 2 --separator ':' )"
    if [ "${kft}" == "${filename}" ] || [ "${kfn}" == "${filename}" ]
    then
      print_plain --message "${kft}" --format "%b"
      return "${PASS}"
    fi
  done
  return "${FAIL}"
}

find_output_file()
{
  __debug $@

  typeset channel=
  
  OPTIND=1
  while getoptex "c. channel." "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel' ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${channel}" )" -eq "${YES}" ]
  then
    get_latest_output_file
    return "${PASS}"
  fi
  
  typeset __known_files="$( get_all_output_files )"
  typeset kf
  for kf in ${__known_files}
  do
    typeset kft="$( get_element --data "${kf}" --id 1 --separator ':' )"
    typeset kfn="$( get_element --data "${kf}" --id 2 --separator ':' )"
    if [ "${kft}" == "${channel}" ] || [ "${kfn}" == "${channel}" ]
    then
      print_plain --message "${kfn}" --format "%s"
      return "${PASS}"
    fi
  done
  return "${FAIL}"
}

get_all_output_channels()
{
  [ -f "${__FILEMGRFILE}" ] && \cut -f 1 -d ':' "${__FILEMGRFILE}"
}

get_all_output_files()
{
  [ -f "${__FILEMGRFILE}" ] && \tr '\n' ' ' < "${__FILEMGRFILE}"
}

get_all_persistent_channels()
{
  [ -f "${__FILEMGRFILE}" ] && \awk -F ':' '$3 == "1" {print $1}' "${__FILEMGRFILE}"
}

get_all_persistent_files()
{
  [ -f "${__FILEMGRFILE}" ] && \awk -F ':' '$3 == "1" {print $2}' "${__FILEMGRFILE}"
}

get_latest_output_file()
{
  [ -f "${__FILEMGRFILE}" ] && \tail -1 "${__FILEMGRFILE}" | \cut -f 2 -d ':'
}

get_latest_generated_output_file()
{
  [ -f "${__FILEMGRFILE}" ] && \grep "${__FILEMARKER}" "${__FILEMGRFILE}" | \tail -1 | \cut -f 2 -d ':'
}

get_latest_output_channel()
{
  [ -f "${__FILEMGRFILE}" ] && \tail -1 "${__FILEMGRFILE}" | \cut -f 1 -d ':'
}

get_latest_generated_output_channel()
{
  [ -f "${__FILEMGRFILE}" ] && \grep "${__FILEMARKER}" "${__FILEMGRFILE}" | \tail -1 | \cut -f 1 -d ':'
}

get_number_output_files()
{
  if [ ! -f "${__FILEMGRFILE}" ]
  then
    printf "%d\n" 0
  else
    __get_line_count "${__FILEMGRFILE}"
  fi
}

get_number_persistent_files()
{
  if [ ! -f "${__FILEMGRFILE}" ]
  then
    printf "%d\n" 0
  else
    __get_line_count "$( get_all_persistent_channels )"
  fi
}

is_channel_in_use()
{
  __debug $@
  
  typeset channel
  
  OPTIND=1
  while getoptex "c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'  ) channel="${OPTARG}";;
   esac
  done
  shift $(( OPTIND-1 ))
  
  if [ "$( is_empty --str "${channel}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  ###
  ### Use grep to make it faster than looking through for-loop
  ###
  \grep -q "^${channel}:" "${__FILEMGRFILE}"
  if [ $? -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

is_channel_persistent()
{
  __debug $@
  
  typeset channel
  
  OPTIND=1
  while getoptex "c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'  ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  typeset channel_in_use="$( is_channel_in_use --channel "${channel}" )"
  if [ "${channel_in_use}" -ne "${YES}" ]
  then
    print_no
  else
    typeset matched_entry="$( \grep -n "^${channel}:" "${__FILEMGRFILE}" | \cut -f 1 -d ':' )"
    typeset persist_marker="$( \sed -n "${matched_entry}p" "${__FILEMGRFILE}" | \cut -f 3 -d ':' )"
    if [ -z "${persist_marker}" ] || [ "${persist_marker}" -ne "${YES}" ]
    then
      print_no
    else
      print_yes
    fi
  fi
  return "${PASS}"
}

make_next_available_channel_for_file()
{
  __debug $@

  typeset filename=
  typeset channel_match=
  typeset persist_opt=
  
  OPTIND=1
  while getoptex "m: match: f: filename: persist" "$@"
  do
    case "${OPTOPT}" in
    'm'|'match'     ) channel_match="${OPTARG}";;
    'f'|'filename'  ) filename="${OPTARG}";;
        'persist'   ) persist_opt="--persist";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset last_channel_gen=
  if [ -z "${channel_match}" ]
  then
    last_channel="$( get_latest_generated_output_channel )"
  else
    last_channel="$( get_all_output_channels | \tr ' ' '\n' | \grep "${channel}" | \tail -n 1 )"
  fi
  
  typeset last_id=$( printf "%s\n" "${last_channel}" | \sed -e 's#[A-Za-z_]*##' )
  [ -z "${last_id}" ] && last_id=0
  
  typeset next_id=$(( last_id + 1 ))
  typeset possible_channel=
  if [ -z "${channel_match}" ]
  then
    possible_channel="${__FILEMARKER}_${next_id}"
  else
    possible_channel="${channel_match}_${next_id}"
  fi
  while [ "$( is_channel_in_use --channel "${possible_channel}" )" -eq "${YES}" ]
  do
    if [ -z "${channel_match}" ]
    then
      possible_channel="${__FILEMARKER}_${next_id}"
    else
      possible_channel="${channel_match}_${next_id}"
    fi
    next_id=$(( next_id + 1 ))
  done
  
  [ "$( is_empty --str "${filename}" )" -eq "${NO}" ] && associate_file_to_channel --filename "${filename}" --channel "${possible_channel}" --ignore-file-existence ${persist_opt}

  printf "%s\n" "${possible_channel}"
  return "${PASS}"
}

make_output_file()
{
  __debug $@
  
  typeset channel
  typeset prefix
  typeset suppress="${NO}"
  typeset unique="${NO}"
  typeset access=
  typeset directory=
  typeset persist="${NO}"
  
  OPTIND=1
  while getoptex "c: channel: p. prefix. s suppress u unique a: access: directory: persist" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    'p'|'prefix'    ) prefix="${OPTARG}";;
    'a'|'access'    ) access="${OPTARG}";;
    's'|'suppress'  ) suppress="${YES}";;
    'u'|'unique'    ) unique="${YES}";;
        'directory' ) directory="${OPTARG}";;
        'persist'   ) persist="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${prefix}" )" -eq "${YES}" ] && prefix='output'

  typeset __known_files="$( get_all_output_files )"

  if [ "$( is_empty --str "${channel}" )" -eq "${YES}" ]
  then
    typeset ftcnt=$( printf "%s " "${__known_files}" | \tr ' ' '\n' | \grep -c "${__FILEMARKER}" | \cut -f 1 -d ' ' )
    channel="${__FILEMARKER}${ftcnt}"
  else
    [ "${unique}" -eq "${YES}" ] && channel="$( make_unique_channel_name --channel "${channel}" )"
    typeset filename="$( find_output_file --channel "${channel}" )"
    if [ "$( is_empty --str "${filename}" )" -eq "${NO}" ]
    then
      [ "${suppress}" -eq "${NO}" ] && print_plain --format "%b" --message "${filename}"
      return "${PASS}"
    fi
  fi

  typeset tmpfile="$( \mktemp -t "${prefix}.${__TEMP_PATTERN}" )"
  [ $? -ne "${PASS}" ] && return "${FAIL}"

  if [ -n "${directory}" ]
  then
    \mkdir -p "${directory}"
    typeset alt_tmpfile="${directory}/$( \basename "${tmpfile}" )"
    \mv -f "${tmpfile}" "${alt_tmpfile}"
    tmpfile="${alt_tmpfile}"
  fi
  
  __CURRENT_FILE="${tmpfile}"

  if [ "$( is_empty --str "${__known_files}" )" -eq "${YES}" ]
  then
    __known_files="${channel}:${tmpfile}"
  else
    __known_files="${__known_files} ${channel}:${tmpfile}"    
  fi
  
  [ "${persist}" -eq "${YES}" ] && __known_files="${__known_files}:${YES}"

  printf "%s " "${__known_files}" | \tr -s ' ' | \tr ' ' '\n' > "${__FILEMGRFILE}"
  if [ "${suppress}" -eq "${NO}" ]
  then
    if [ "${unique}" -eq "${YES}" ]
    then
      print_plain --format "%b" --message "${channel}:${tmpfile}"
    else
      print_plain --format "%b" --message "${tmpfile}"
    fi
  fi

  [ -n "${access}" ] && \chmod ${access} "${tmpfile}"
  __CURRENT_FILE=
  return "${PASS}"
}

make_unique_channel_name()
{
  __debug $@

  typeset channel=

  OPTIND=1
  while getoptex "c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel' ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${channel}" )" -eq "${YES}" ]
  then
    typeset __known_files="$( get_all_output_files )"
    typeset ftcnt=$( printf "%s " "${__known_files}" | \tr ' ' '\n' | \grep -c "${__FILEMARKER}" | \cut -f 1 -d ' ' )
    channel="${__FILEMARKER}${ftcnt}"
  else
    [ "$( is_channel_in_use --channel "${channel}" )" -eq "${YES}" ] && channel+='_'$( __today_as_seconds )
  fi
  printf "%s\n" "${channel}"
  return "${PASS}"
}

mark_channel_persistent()
{
  __debug $@
  
  typeset channel
  typeset remove
  
  OPTIND=1
  while getoptex "c: channel: r remove" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'  ) channel="${OPTARG}";;
    'r'|'remove'   ) remove="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset matched_entry=$( \grep -n "^${channel}:" "${__FILEMGRFILE}" | \cut -f 1 -d ':' )
  [ -z "${matched_entry}" ] && return "${FAIL}"
  ###
  ### Need to lock the file in the event multiple entries are attempting to access it
  ###
  typeset tmpfmgr="${__FILEMGRFILE}.tmp"
  typeset original="$( \sed -n "${matched_entry}p" "${__FILEMGRFILE}" )"
  original="$( printf "%s\n" "${original}" | \cut -f -2 -d ':' )"
  ## LOCK
  \sed "${matched_entry}d" "${__FILEMGRFILE}" >> "${tmpfmgr}"
  if [ -n "${remove}" ]
  then
    printf "%s\n" "${original}" >> "${tmpfmgr}"
  else
    printf "%s\n" "${original}:${YES}" >> "${tmpfmgr}"
  fi
  \mv -f "${tmpfmgr}" "${__FILEMGRFILE}"
  ### UNLOCK
  return "${PASS}"
}

register_tmpfile()
{
  __debug $@

  typeset channel='__global_DISCARD'
  typeset filename=

  OPTIND=1
  while getoptex "f: filename: c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename' ) filename="${OPTARG}";;
    'c'|'channel'  ) channel="__${OPTARG}_DISCARD";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && [ ! -f "${filename}" ] && return "${PASS}"

  make_output_file --channel "${channel}" --prefix '__discard' >/dev/null 2>&1
  append_output --data "${filename}" --channel "${channel}" --raw
  
  typeset discardfile="$( find_output_file --channel "${channel}" )"
  if [ -n "${discardfile}" ] && [ -f "${discardfile}" ]
  then
    \sort -u "${discardfile}" > "${discardfile}.sort"
    \mv -f "${discardfile}.sort" "${discardfile}"
  fi
  return "${PASS}"
}

remove_channel()
{
  __debug $@

  typeset channel=

  OPTIND=1
  while getoptex "c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset __known_files=$( get_all_output_files )
  printf "%s " "${__known_files}" | \tr -s ' ' | \tr ' ' '\n' | \grep -v "^${channel}" > "${__FILEMGRFILE}"

  return "${PASS}"
}

remove_output_file()
{
  __debug $@
  
  typeset channel=
  typeset filename=
  
  OPTIND=1
  while getoptex "c: channel: f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'   ) channel="${OPTARG}";;
    'f'|'filename'  ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset outputfile=
  if [ -n "${channel}" ]
  then
    outputfile="$( find_output_file --channel "${channel}" )"
    [ "$( is_empty --str "${outputfile}" )" -eq "${YES}" ] && return "${FAIL}"
  else
    outputfile="${filename}"
  fi
  
  if [ -n "${outputfile}" ]
  then
    channel="$( find_output_channel --file "${outputfile}" )"

    typeset should_persist="$( is_channel_persistent --channel "${channel}" )"
    if [ -z "${should_persist}" ] || [ "${should_persist}" -ne "${YES}" ]
    then
      [ -f "${outputfile}" ] && \rm -f "${outputfile}" >/dev/null 2>&1
      typeset __known_files=$( get_all_output_files )
      printf "%s " "${__known_files}" | \tr -s ' ' | \tr ' ' '\n' | \grep -v "${outputfile}" > "${__FILEMGRFILE}"
    fi
  fi
  return "${PASS}"
}

remove_all_output_files()
{
  __debug $@

  typeset __known_files="$( get_all_output_files )"
  typeset kf
  for kf in ${__known_files}
  do
    typeset kft="$( printf "%s\n" "${kf}" | \cut -f 1 -d ':' )"
    remove_output_file --channel "${kft}"
  done
  return "${PASS}"
}

reset_output_file()
{
  __debug $@
  typeset channel
  
  OPTIND=1
  while getoptex "c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel' ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset outputfile="$( find_output_file --channel "${channel}" )"
  [ "$( is_empty --str "${outputfile}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ -f "${outputfile}" ]
  then
    \rm -f "${outputfile}"
    \touch "${outputfile}"
    return "${PASS}"
  fi
  
  return "${FAIL}"
}

store_output()
{
  __debug $@
  typeset data
  typeset filename
  typeset channel
  
  OPTIND=1
  while getoptex "d: data: f: filename: c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'     ) data="${OPTARG}";;
    'f'|'filename' ) filename="${OPTARG}";;
    'c'|'channel'  ) channel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${data}" )" -eq "${YES}" ] && return "${PASS}"
  
  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && [ "$( is_empty "${channel}" )" -eq "${YES}" ]
  then
    filename="$( make_output_file )"
    channel="$( find_output_channel --file "${filename}" )"
  else
    [ "$( is_empty --str "${channel}" )" -eq "${YES}" ] && channel="$( find_output_channel --file "${filename}" )"
  fi
  
  append_output --data "${data}" --channel "${channel}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null

  . "${SLCF_SHELL_TOP}/lib/timemgt.sh"
fi

__initialize_base_logging
__prepared_base_logging
