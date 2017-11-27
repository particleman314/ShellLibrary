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
## @Software Package : Shell Automated Testing -- File Assertions
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.06
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    assert_directory_contents_match
#    assert_files_same
#    assert_has_filesize
#    assert_is_directory
#    assert_is_executable
#    assert_is_file
#    assert_is_file_or_link
#    assert_same_file
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC2181,SC2090,SC1117,SC2086,SC2089

[ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

# shellcheck source=/dev/null

[ -z "${__INITIALIZE_ASSERTIONS}" ] && . "${SLCF_SHELL_TOP}/lib/assertions.sh"

assert_directory_contents_match()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset def_hasher='md5sum'
  typeset hasher="${def_hasher}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: c: cause: h: hasher:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
    'h'|'hasher'   ) hasher="${OPTARG}";;
        'dnr'      ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  \which "${hasher}" > /dev/null 2>&1
  [ $? -ne 0 ] && hasher="${def_hasher}"

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Directory Contents Match" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  if [ -z "${expectation}" ] || [ -z "${actual}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return "$( __get_last_result )"
  fi

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause $( __space_handler 'Directory contents do not align' )"
  else
    speciality_args+=" --cause ${cause}"
  fi

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  typeset snap_image_before="${expectation}"
  typeset after_dir="${actual}"

  typeset tmpfile="$( make_output_file )"
  typeset snap_image_after=$( snap_directory_listing --directory "${after_dir}" --style after --output-file "${tmpfile}" )

  typeset new_files=
  typeset after_files=$( \cat "${snap_image_after}" )
  typeset af=

  for af in ${after_files}
  do
    \grep -q "${af}" "${snap_image_before}" > /dev/null 2>&1
    [ $? -ne "${PASS}" ] && new_files+=" ${af}"
  done
  
  typeset before_md5=
  typeset after_md5=
  [ -n "${snap_image_before}" ] && before_md5=$( ${hasher} "${snap_image_before}" | \tr -s ' ' | \cut -f 1 -d ' ' )
  [ -n "${snap_image_after}" ] && after_md5=$( ${hasher} "${snap_image_after}" | \tr -s ' ' | \cut -f 1 -d ' ' )
  
  typeset add_on_info=
  if [ -n "${new_files}" ]
  then
    new_files=$( printf "%s\n" "${new_files}" | \sed -e 's#^ ##' -e 's# #,#g' )
    add_on_info=": new files found -- ${new_files}"
  else
    add_on_info=": Hasher << ${hasher} >> checksums don't match"
  fi
  
  assert_equals ${speciality_args} "${before_md5}" "${after_md5}" "${add_on_info}"
  remove_output_file --filename "${tmpfile}"
  
  return "${PASS}"
}

assert_files_same()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"
  typeset diff_options=

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: o: diffopts: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "$OPTARG}" )";;
    'o'|'diffopts' ) diff_options="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Files Same" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  if [ -z "${expectation}" ] || [ -z "${answer}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return $?
  fi

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ ! -f "${expectation}" ] || [ ! -f "${answer}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "File(s) <${expectation}> and/or <${answer}> are not the available" )\""
    __record_fail ${speciality_args} --expect 0 --actual 127
    return $?
  fi

  if [ -z "${cause}" ]
  then
    if [ "${modifier}" != "${__POSITIVE}" ]
    then
      speciality_args+=" --cause $( __space_handler "Files << ${expectation} >> and << ${answer} >> are not different" )"
    else
      speciality_args+=" --cause $( __space_handler "Files << ${expectation} >> and << ${answer} >> are different" )"
    fi
  else
    speciality_args+=" --cause ${cause}"
  fi

  \diff ${diff_options} "${expectation}" "${answer}" >/dev/null 2>&1
  typeset RC=$?

  typeset softRC="${PASS}"
  [ "${RC}" -gt 0 ] && softRC="${FAIL}"

  if [ "${softRC}" -eq "${PASS}" ]
  then
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Same" )"
    else
      __record_fail ${speciality_args} --title "$( __space_handler "Not Same File" )" --expected '1' --actual "${softRC}"
    fi
  else
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      __record_fail ${speciality_args} --title "$( __space_handler "Same File" )" --expected '0' --actual "${softRC}"
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Not Same" )"
    fi
  fi
  return "${PASS}"
}

assert_has_filesize()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert File Size" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return "${FAIL}"
  fi

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause $( __space_handler 'Non file found' )"
  else
    speciality_args+=" --cause ${cause}"
  fi

  if [ ! -f "${expectation}" ]
  then
    __record_fail ${speciality_args} ${parameter_args}
    return "${PASS}"
  fi

  typeset fs=$( __calculate_filesize "${expectation}" )
  if [ "${modifier}" == "${__POSITIVE}" ]
  then
    assert_greater ${speciality_args} "${fs}" 0
  else
    assert_equals ${speciality_args} "${fs}" 0
  fi
  
  return "${PASS}"
}

assert_is_directory()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Directory" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'No input found' )\""
    __record_fail ${speciality_args} ${parameter_args}
    return "${PASS}"
  fi

  if [ -z "${cause}" ]
  then
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Non directory found' )"
    else
      speciality_args+=" --cause $( __space_handler 'Directory found' )"
    fi
  else
    speciality_args+=" --cause ${cause}"
  fi

  if [ "${modifier}" == "${__POSITIVE}" ]
  then
    if [ ! -d "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert Directory Found" )"
    fi
  else
    if [ -d "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert Directory Not Found" )"
    fi
  fi
  return "${PASS}"
}

assert_is_executable()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Executable File" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'No input found' )\""
    __record_fail ${speciality_args} ${parameter_args}
    return "${PASS}"
  fi

  if [ -z "${cause}" ]
  then
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Non executable file found' )"
    else
      speciality_args+=" --cause $( __space_handler 'Executable file found' )"
    fi
  else
    speciality_args+=" --cause ${cause}"
  fi

  if [ "${modifier}" == "${__POSITIVE}" ]
  then
    if [ ! -x "${expectation}" ] || [ -d "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert Executable File Found" )"
    fi
  else
    if [ -x "${expectation}" ] && [ ! -d "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert Executable File Not Found" )"
    fi
  fi
  return "${PASS}"
}

assert_is_file()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert File" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return "${PASS}"
  fi

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'No input found' )\""
    __record_fail ${speciality_args} ${parameter_args}
    return "${PASS}"
  fi

  if [ -z "${cause}" ]
  then
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Non file found' )"
    else
      speciality_args+=" --cause $( __space_handler 'File found' )"
    fi
  else
    speciality_args+=" --cause ${cause}"
  fi

  if [ "${modifier}" == "${__POSITIVE}" ]
  then
    if [ ! -f "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Found" )"
    fi
  else
    if [ -f "${expectation}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Not Found" )"
    fi
  fi
  return "${PASS}"
}

assert_is_file_or_link()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset modifier="${__POSITIVE}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: modify: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
        'modify'   ) modifier="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert File Or Link" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"

  if [ -z "${expectation}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return "${PASS}"
  fi

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${cause}" ]
  then
    if [ "${modifier}" == "${__POSITIVE}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Non file/link found' )"
    else
      speciality_args+=" --cause $( __space_handler 'File/Link found' )"
    fi
  else
    speciality_args+=" --cause ${cause}"
  fi

  typeset possible_linkage="$( \ls -l "${expectation}" | \sed 's/^.* -> //' )"
  [ -z "${possible_linkage}" ] && possible_linkage='___'
  
  if [ "${modifier}" == "${__POSITIVE}" ]
  then
    if [ ! -f "${expectation}" ] && [ "${expectation}" == "${possible_linkage}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Or Link Found" )"
    fi
    return "${PASS}"
  else
    if [ -f "${expectation}" ] || [ "${expectation}" != "${possible_linkage}" ]
    then
      __record_fail ${speciality_args} ${parameter_args}
    else
      __record_pass ${speciality_args} ${parameter_args} --title "$( __space_handler "Assert File Or Link Not Found" )"
    fi
  fi
  return "${PASS}"
}

assert_same_file()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset cause=
  typeset suppression="${NO}"
  typeset dnr="${NO}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename: c: cause:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;
    's'|'suppress' ) suppression="${OPTARG}";;
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
        'dnr'      ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Same File" )"
  fi

  typeset expectation="$( __space_handler "$1" )"
  typeset actual="$( __space_handler "$2" )"
  shift 2

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  if [ -z "${expectation}" ] || [ -z "${actual}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return "${PASS}"
  fi

  if [ ! -f "${expectation}" ] || [ ! -f "${actual}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "File(s) <${expectation}> and/or <${actual}> are not available" )\""
    __record_fail ${speciality_args} --expect 0 --actual 127
    return "${PASS}"
  fi

  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"

  typeset h1=$( \md5sum "${expectation}" | \cut -f 1 -d ' ' )
  typeset h2=$( \md5sum "${actual}" | \cut -f 1 -d ' ' )

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}:${h1}"
  [ -n "${actual}" ] && parameter_args+=" --actual ${actual}:${h2}"

  if [ "${h1}" != "${h2}" ] 
  then
    __record_fail ${speciality_args} ${parameter_args}
  else
    __record_pass ${speciality_args} ${parameter_args}
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
