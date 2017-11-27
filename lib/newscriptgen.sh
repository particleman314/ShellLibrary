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
## @Software Package : Shell Automated Testing -- New Script Generation
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.00
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __add_content_file
#    __has_header
#    __has_disclaimer
#    add_content_type
#    add_disclaimer
#    add_header
#
###############################################################################

# shellcheck disable=SC2016,SC2068,SC2039,SC2181

[ -z "${__BACKUP_EXTENSION}" ] && __BACKUP_EXTENSION='bck'

__add_content_file()
{
  __debug $@

  typeset backup_ext="${__BACKUP_EXTENSION}"
  typeset filename=
  typeset contentfile=
  typeset rmbackup="${YES}"

  OPTIND=1
  while getoptex "f: file: c: contentfile: k. keep-backup. b. backup-extension." "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'             ) filename="${OPTARG}";;
    'c'|'contentfile'      ) contentfile="${OPTARG}";;
    'k'|'keep-backup'      ) rmbackup="${NO}";;
    'b'|'backup-extension' ) backup_ext="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${filename}" )" -eq "${YES}" ]
  then
    return "${FAIL}"
  else
    [ ! -f "${contentfile}" ] && return "${FAIL}"

    typeset tmpfile="$( make_temp_file )"

    [ "$( is_empty --str "${tmpfile}" )" -eq "${YES}" ] && return "${FAIL}"
    [ -f "${filename}.${backup_ext}" ] && \rm -f "${filename}.${backup_ext}"

    \cat "${contentfile}" > "${tmpfile}"
    \cat "${filename}" >> "${tmpfile}"
    \cp -pr "${filename}" "${filename}.${backup_ext}"

    [ ! -f "${filename}.${backup_ext}" ] && print_plain --message "[ ERROR ] Unable to copy original file to make backup..."

    \mv -f "${tmpfile}" "${filename}"

    if [ -f "${tmpfile}" ]
    then
      print_plain --message "[ WARN ] Unable to remove temporary file --> ${tmpfile}.  Please do so manually!"
    else
      \chmod 0644 "${filename}"
    fi

    [ "${rmbackup}" -eq "${YES}" ] && [ -f "${filename}.${backup_ext}" ] && \rm -f "${filename}.${backup_ext}"
  fi
  return "${PASS}"
}

__has_header()
{
  __debug $@

  typeset filename=
  
  OPTIND=1
  while getoptex "f: file:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${NO}"

  typeset match="$( find_match_in_file --file "${filename}" --pattern "Software Package : " )"
  [ $? -eq "${PASS}" ] && [ "$( is_empty --str "${match}" )" -eq "${NO}" ] && return "${YES}"
  return "${NO}"
}

__has_disclaimer()
{
  __debug $@

  typeset filename=
  
  OPTIND=1
  while getoptex "f: file:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file' ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${NO}"

  typeset match="$( find_match_in_file --file "${filename}" --pattern "IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE" )"
  [ $? -eq "${PASS}" ] && [ "$( is_empty --str "${match}" )" -eq "${NO}" ] && return "${YES}"
  return "${NO}"
}

__initialize_newscriptgen()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"
  __initialize "__initialize_newscriptgen"
}

__prepared_newscriptgen()
{
  __prepared "__prepared_newscriptgen"
}

add_content_type()
{
  __debug $@
  
  typeset filename=
  typeset content_type=

  OPTIND=1
  while getoptex "c: content: f: file:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'    ) filename="${OPTARG}";;
    'c'|'content' ) content_type="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${content_type}" )" -eq "${YES}" ] && content_type='disclaimer'
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset funccall="__has_${content_type}"
  #typeset RC=$( fn_exists ${funccall} )

  #[ "${RC}" -ne "${PASS}" ] && return "${RC}"

  eval "${funccall} --file \"${filename}\""
  RC=$?
  
  if [ "${RC}" -eq "${NO}" ]
  then
    eval "add_${content_type} --file \"${filename}\""
    RC=$?
  else
    print_plain --message "Already detected ${content_type} within file..."
  fi

  return "${RC}"
}

add_disclaimer()
{
  __debug $@
  
  typeset filename=
  typeset disclaimer=
  typeset rmbackup="${YES}"

  OPTIND=1
  while getoptex "f: file: c: contentfile: k. keep-backup." "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'          ) filename="${OPTARG}";;
    'c'|'contentfile'   ) disclaimer="${OPTARG}";;
    'k'|'keep-backup'   ) rmbackup="${NO}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  # Need to add capability of substitution where necessary (base list and user augmented list)
  typeset current_year="$( \date "+%Y" )"

  [ "$( is_empty --str "${disclaimer}" )" -eq "${YES}" ] && disclaimer="${SLCF_SHELL_TOP}/resources/common/disclaimer.txt"
  typeset RC="${PASS}"

  __add_content_file --file "${filename}" --contentfile "${disclaimer}" --keep-backup "$( invert "${rmbackup}" )"
  RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    print_plain --message "Unable to properly complete request to add disclaimer information!"
    print_plain --message "File queried --> <<${disclaimer}>> for inclusion into <<${filename}>>"
  fi

  return "${RC}"
}

add_header()
{
  __debug $@

  typeset filename=
  typeset simple_header=
  typeset rmbackup="${YES}"

  OPTIND=1
  while getoptex "f: file: c: contentfile: k. keep-backup." "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'          ) filename="${OPTARG}";;
    'c'|'contentfile'   ) simple_header="${OPTARG}";;
    'k'|'keep-backup'   ) rmbackup="${NO}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  [ "$( is_empty --str "${simple_header}" )" -eq "${YES}" ] && simple_header="${SLCF_SHELL_TOP}/resources/common/pkgdetail.txt"
  typeset RC="${PASS}"

  __add_content_file --file "${filename}" --contentfile "${simple_header}" --keep-backup "$( invert "${rmbackup}" )"
  RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    print_plain --message "Unable to properly complete request to add header information!"
    print_plain --message "File queried --> << ${simple_header} >> for inclusion into << ${filename} >>"
  fi

  return "${RC}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/filemgt.sh"
fi

__initialize_newscriptgen
__prepared_newscriptgen
