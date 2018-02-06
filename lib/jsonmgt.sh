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
## @Software Package : Shell Automated Testing -- JSON Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.01
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __disable_json_failure 
#    __enable_json_failure
#    __json_suppression
#    call_json_with_filter
#    json_check_file
#    json_convert_2_text_list
#    json_exists
#    json_fail
#    json_get_channel
#    json_get_matching_entry
#    json_get_subjson
#    json_merge
#    json_set_channel
#    json_set_file
#    json_unset_file
#    json_validate
#
###############################################################################

__disable_json_failure()
{
  typeset setting="${1:-${YES}}"

  if [ -z "${__JSON_FAILURE_SUPPRESSION}" ]
  then
    __JSON_FAILURE_SUPPRESSION="${YES}"
  else
    __JSON_FAILURE_SUPPRESSION=$(( __JSON_FAILURE_SUPPRESSION + ${setting} ))
  fi
  __JSON_FAILURE_SUPPRESSION=$( __range_limit "${__JSON_FAILURE_SUPPRESSION}" "${NO}" "${YES}" )
}

__enable_json_failure()
{
  __JSON_FAILURE_SUPPRESSION="${NO}"
}

__initialize_jsonmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  # Requires 'jq' to be available on the system
  __load __initialize_debugging "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  
  [ -z "${__STD_JSONFILE}" ] && __STD_JSONFILE=
  __initialize "__initialize_jsonmgt"
  
  ### Remove coloring and use raw output
  __DEFAULT_JQ_OPTIONS='--compact-output --raw-output -e '
  __JSON_TRACING_CHANNEL='JSON'
}

__json_suppression()
{
  typeset msg="$1"

  [ "$( is_empty --str "${msg}" )" -eq "${YES}" ] && return "${PASS}"

  if [ "${__JSON_FAILURE_SUPPRESSION}" -eq "${NO}" ]
  then
    print_plain --message "[ ERROR ] ${msg}"
    append_output --channel ERROR --data "${msg}"
  elif [ "${__JSON_FAILURE_SUPPRESSION}" -eq "${YES}" ]
  then
    append_output --channel ERROR --data "${msg}"
  fi

  return "${PASS}"
}

__prepared_jsonmgt()
{
  __prepared "__prepared_jsonmgt"
}

call_json_with_filter()
{
  __debug $@

  [ -z "${jq_exe}" ] && return "${FAIL}"

  typeset jsonfile
  typeset filters
  typeset remarr="${NO}"
  
  OPTIND=1
  while getoptex "j: jsonfile: f: filter: remove-array" "$@"
  do
    case "${OPTOPT}" in
    'j'|'jsonfile'     ) jsonfile="${OPTARG}";;
    'f'|'filter'       ) filters+="${OPTARG} ";;
        'remove-array' ) remarr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && jsonfile="${__STD_JSONFILE}"
  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && return "${FAIL}"

  json_check_file --jsonfile "${jsonfile}"
  typeset RC=$?

  [ "${RC}" -ne "${PASS}" ] && return "${NO}"

  typeset filter=
  typeset f=
  for f in ${filters}
  do
    [ -z "${filter}" ] && filter="${f}" || filter="${filter} | ${f}"
  done

  [ "${remarr}" -eq "${YES}" ] && filter+=" | .[]?"
  
  typeset output="$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} "${filter}" "${jsonfile}" 2>/dev/null )"
  RC=$?
  append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} \"${filter}\" \"${jsonfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__JSON_TRACING_CHANNEL}"
  [ "${output}" == 'null' ] && [ "${RC}" -ne "${PASS}" ] && output=''
  
  [ -n "${output}" ] && printf "%s\n" "${output}"
  return "${RC}"
}

json_check_file()
{
  __debug $@

  typeset jsonfile=
  typeset errorcode="${FAIL}"

  OPTIND=1
  while getoptex "j: jsonfile: e: errorcode:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'errorcode' ) errorcode="${OPTARG}";;
    'j'|'jsonfile'  ) jsonfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ]
  then
    json_fail --message "No JSON file provided" --errorcode "${errorcode}"
    return $?
  elif [ ! -f "${jsonfile}" ]
  then
    json_fail --message "Unable to find necessary JSON file : < ${jsonfile} >" --errorcode "${errorcode}"
    return $?
  fi

  return "${PASS}"
}

json_convert_2_text_list()
{
  __debug $@

  typeset input=
  
  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  printf "%s\n" "${input}" | \sed -e 's#^\[##' -e 's#\]$##' | \tr '"' ' ' | \tr '\n' ' ' | \sed -e 's# ##g'
  return "${PASS}"
}

json_exists()
{
  __debug $@

  [ -z "${jq_exe}" ] && return "${NO}"

  typeset jsonfile
  typeset jpath
  typeset msg='Unable to find requested element'

  OPTIND=1
  while getoptex "p: jpath: m: msg: message: j. jsonfile." "$@"
  do
    case "${OPTOPT}" in
    'p'|'jpath'         ) jpath="${OPTARG}";;
    'j'|'jsonfile'      ) jsonfile="${OPTARG}";;
    'm'|'msg'|'message' ) msg="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && jsonfile="${__STD_JSONFILE}"
  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && return "${NO}"

  json_check_file --jsonfile "${jsonfile}"
  typeset RC=$?

  [ "${RC}" -ne "${PASS}" ] && return "${NO}"

  typeset filter='.[]'
  if [ "$( is_empty --str "${jpath}" )" -eq "${YES}" ]
  then
    json_fail --message "No jpath provided"
    return "${NO}"
  else
    filter="${jpath}"
  fi

  typeset filters="$@"
  typeset f=
  for f in ${filters}
  do
    filter+=" | ${f}"
  done

  typeset output="$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} "${filter}" "${jsonfile}" 2>/dev/null )"
  RC=$?
  append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} \"${filter}\" \"${jsonfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__JSON_TRACING_CHANNEL}"

  if [ "$( is_empty --str "${output}" )" -eq "${YES}" ]
  then
    json_fail --message "${jpath} : ${msg}"
    return "${NO}"
  fi
  return "${YES}"
}

json_fail()
{
  __debug $@
  
  typeset msg
  typeset errorcode="${FAIL}"

  OPTIND=1
  while getoptex "m: msg: message: e: errorcode:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'errorcode'     ) errorcode="${OPTARG}";;
    'm'|'msg'|'message' ) msg="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${msg}" )" -eq "${NO}" ] && __json_suppression "${msg}"

  return "${errorcode}"
}

json_get_channel()
{
  __debug $@
  printf "%s\n" "${__JSON_TRACING_CHANNEL}"
  return "${PASS}"
}

json_get_matching_entry()
{
  __debug $@
  
  [ -z "${jq_exe}" ] && return "${FAIL}"

  typeset jsonfile=
  typeset jpath=
  typeset match=
  typeset field=

  OPTIND=1
  while getoptex "j. jsonfile. p: jpath: m: match: f: field:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'jpath'    ) jpath="${OPTARG}";;
    'x'|'jsonfile' ) jsonfile="${OPTARG}";;
    'm'|'match'    ) match="${OPTARG}";;
    'f'|'field'    ) field="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${field}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${match}" )" -eq "${YES}" ] && return "${FAIL}"

  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && jsonfile="${__STD_JSONFILE}"
  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && return "${FAIL}"

  json_check_file --jsonfile "${jsonfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset details="$@"
  typeset output="$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} "${jpath}[@${match}]" -v "${field}" ${details} "${jsonfile}" )"

  [ "$( is_empty --str "${output}" )" -ne "${YES}" ] && printf "%q" "${output}"
  append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} \"${jpath}[@${match}]\" -v \"${field}\" ${details} \"${jsonfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__JSON_TRACING_CHANNEL}"

  return "${PASS}"
}

json_get_subjson()
{
  __debug $@
  
  if [ -z "${jq_exe}" ]
  then
    return "${FAIL}"
  fi

  typeset jsonfile
  typeset jpath

  typeset subjsonfile="$( make_output_file --channel 'SUBJSON' --unique )"
  [ "$( is_empty --str "${subjsonfile}" )" -eq "${YES}" ] && return "${FAIL}"
 
  typeset channel="$( get_element --data "${subjsonfile}" --id 1 --separator ':' )"
  subjsonfile="$( get_element --data "${subjsonfile}" --id 2 --separator ':' )"
  
  OPTIND=1
  while getoptex "j. jsonfile. p: jpath:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'jpath'    ) jpath="${OPTARG}";;
    'j'|'jsonfile' ) jsonfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && jsonfile="${__STD_JSONFILE}"
  [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] && return "${FAIL}"

  json_check_file --jsonfile "${jsonfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset details="$@"
  typeset output="$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} "${jpath}" ${details} "${jsonfile}" > "${subjsonfile}" )"

  if [ $? -eq "${PASS}" ]
  then
    printf "%q" "${subjsonfile}"
  else
    remove_output_file --channel "${channel}"
    return "${FAIL}"
  fi

  append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} \"${jpath}\" ${details} \"${jsonfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__JSON_TRACING_CHANNEL}"
  return "${PASS}"
}

json_merge()
{
  __debug $@
  
  [ -z "${jq_exe}" ] && return "${FAIL}"

  typeset RC="${PASS}"
  typeset srcfile
  typeset destfile
  typeset outputfile
  
  OPTIND=1
  while getoptex "s: srcfile: d: destfile: o: outputfile:" "$@"
  do
    case "${OPTOPT}" in
    's'|'srcfile'    ) srcfile="${OPTARG}";;
    'd'|'destfile'   ) destfile="${OPTARG}";;
    'o'|'outputfile' ) outputfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${srcfile}" )" -eq "${YES}" ] || [ ! -f "${srcfile}" ] && return "${FAIL}"
  [ "$( is_empty --str "${destfile}" )" -eq "${YES}" ] || [ ! -f "${destfile}" ] && return "${FAIL}"
  
  [ "${srcfile}" == "${destfile}" ] && return "${PASS}"
  [ "${outputfile}" == "${destfile}" ] && outputfile=
  
  typeset merge_output="$( ${jq_exe} ${__DEFAULT_JQ_OPTIONS} --argfile f1 "${destfile}" --argfile f2 "${srcfile} -n '$f1 + $f2 | . = $f1. + $f2.'" 2>/dev/null )"
  RC=$?
  [ $( is_empty --str "${merge_output}" ) -eq "${YES}" ] || [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  
  if [ -n "${outputfile}" ]
  then
    printf "%s\n" "${merge_output}" > "${outputfile}"
    append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s add \"${destfile}\" \"${srcfile}\" > \"${outputfile}\" -- {RC = ${RC}} -- '${merge_output}'" --channel "${__JSON_TRACING_CHANNEL}"
  else
    printf "%s\n" "${merge_output}" > "${destfile}"
    append_output --data "${jq_exe} ${__DEFAULT_JQ_OPTIONS} -s add \"${destfile}\" \"${srcfile}\" > \"${destfile}\" -- {RC = ${RC}} -- '${merge_output}'" --channel "${__JSON_TRACING_CHANNEL}"
  fi
  return "${PASS}"
}

json_set_channel()
{
  __debug $@

  typeset jsonchannel=

  OPTIND=1
  while getoptex "j: jsonchannel:" "$@"
  do
    case "${OPTOPT}" in
    'j'|'jsonchannel' ) jsonchannel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${jsonchannel}" ] && return "${FAIL}"
  __JSON_TRACING_CHANNEL="${jsonchannel}"
  return "${PASS}"
}

json_set_file()
{
  __debug $@
  
  typeset jsonfile=

  OPTIND=1
  while getoptex "j: jsonfile:" "$@"
  do
    case "${OPTOPT}" in
    'j'|'jsonfile' ) jsonfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${jsonfile}" )" -eq "${NO}" ] && [ -f "${jsonfile}" ]
  then
    __STD_JSONFILE="${jsonfile}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

json_unset_file()
{
  __STD_JSONFILE=
  return "${PASS}"
}


json_validate()
{
  __debug $@

  if [ -z "${jq_exe}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  typeset jsonfile

  OPTIND=1
  while getoptex "j: jsonfile:" "$@"
  do
    case "${OPTOPT}" in
    'j'|'jsonfile' ) jsonfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${jsonfile}" )" -eq "${YES}" ] || [ ! -f "${jsonfile}" ]
  then
    print_no
    return "${FAIL}"
  fi

  ${jq_exe} ${__DEFAULT_JQ_OPTIONS} '.' "${jsonfile}" > /dev/null 2>&1
  if [ $? -ne "${PASS}" ]
  then
    print_no
  else
    print_yes
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
if [ -z "${__JSON_FAILURE_SUPPRESSION}" ]
then
  __JSON_FAILURE_SUPPRESSION=0
  jq_exe=
fi

\which 'jq' > /dev/null 2>&1
if [ $? -ne 0 ]
then
  \which 'python' > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    printf "[WARN     ] %s\n" "Unable to utilize jsonmgt.sh since << jq|python >> is NOT available from the commandline!" "Please include ${SLCF_SHELL_TOP}/resources/<OSTYPE> in your search path..."
    printf "\n"
    SLCF_LIBRARY_ISSUE=1
  else
    jq_exe="$( \which 'python' ) -c 'import sys, json; print json.load(sys.stdin)"
    use_python_parser_for_json=1
  fi
else
  jq_exe="$( \which 'jq' )"
  yaml_exe="$( \which 'yaml2json' )"
  jq_exe_found=1
fi

if [ "${use_python_parser_for_json}" -eq 1 -o "${jq_exe_found}" -eq 1 ]
then
  type "__initialize" 2>/dev/null | \grep -q 'is a function'

  # shellcheck source=/dev/null
  [ $? -ne 0 ] && . "${SLCF_SHELL_TOP}/lib/base_logging.sh"

  __initialize_jsonmgt
  [ $? -eq 0 ] && __prepared_jsonmgt
fi
