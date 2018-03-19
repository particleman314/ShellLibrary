#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2017.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Program Support
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.52
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __addto_internal_variable
#    __check_for
#    __check_for_preexistence
#    __check_keyword
#    __check_keyword_on
#    __convert_parameter
#    __define_internal_variable
#    __delayed_substitute
#    __escapify
#    __extract_value
#    __find_matching_long_parameter
#    __get_library_attribute
#    __handle_spaced_output
#    __ignore_lines
#    __import_all_variables
#    __import_variable
#    __internal_substitute
#    __make_tab_level
#    __process_spo_match
#    __register_cleanup
#    __replaced_enclosed
#    __set_internal_value
#    __set_option_file
#    __set_program_variable_prefix
#    __setup_paths
#    __setup_program
#    __strindex
#    __substitute
#    __update_overhead
#    __update_dynamic_overhead
#    __update_static_overhead
#    cache_executables
#    display_cached_executables
#    display_cmdline_flags
#    gather_timestamp
#    get_environment
#    get_shell_library_version
#    handle_error_output
#    handle_output
#    handle_premature_exit
#    handle_warning_output
#    help_banner
#    load_program_library
#    log_error
#    log_warning
#    match_program_options
#    print_btf_detail
#    print_program_version
#    process_data
#    record_step
#    request_lock_with_timer
#    setup
#    store_generated_output
#    validate_basic_binaries
#
###############################################################################

if [ -z "${__PROGRAM_OPTION_FILE}" ]
then
  __PROGRAM_OPTION_FILE=
  __PROGRAM_VARIABLE_PREFIX=
fi

__addto_internal_variable()
{
  typeset key="$1"
  typeset value="$2"
  typeset specialized_variable_prefix="$3"
  
  [ -z "${__PROGRAM_VARIABLE_PREFIX}" ] && [ -z "${specialized_variable_prefix}" ] && return "${FAIL}"
  [ -z "${key}" ] && return "${FAIL}"
  
  typeset varname="$( __define_internal_variable "${key}" "${specialized_variable_prefix}" )"
  if [ -n "${value}" ]
  then
    eval "${varname}+=' ${value}'"
  else
    eval "${varname}='${value}'"
  fi
  return "${PASS}"
}

__check_for()
{
  typeset keyid=
  typeset __success="${YES}"
  typeset specialized_variable_prefix=
  
  OPTIND=1
  while getoptex "k: key: s success f failure p: prefix:" "$@"
  do
    case "${OPTOPT}" in
    'k'|'key'       ) keyid="${OPTARG}";;
    's'|'success'   ) __success="${YES}";;
    'f'|'failure'   ) __success="${NO}";;
    'p'|'prefix'    ) specialized_variable_prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${keyid}" ] && return "${FAIL}"
  
  typeset value="$( __extract_value "${keyid}" "${specialized_variable_prefix}" )"
  if [ "${__success}" -eq "${YES}" ]
  then
    if [ -n "${value}" ] && [ "${value}" -eq "${__success}" ]
    then
      print_yes
    else
      print_no
    fi
  else
    if [ -z "${value}" ] || [ "${value}" -eq "${__success}" ]
    then
      print_yes
    else
      print_no
    fi
  fi
  return "${PASS}"
}

__check_for_preexistence()
{
  typeset keyid=
  typeset value=

  OPTIND=1
  while getoptex "k: key: v: value:" "$@"
  do
    case "${OPTOPT}" in
    'k'|'key'     ) keyid="${OPTARG}";;
    'v'|'value'   ) value="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${keyid}" ] && return "${FAIL}"

  typeset result=
  eval "result=\"\${${keyid}}\""
  [ -n "${result}" ] && return "${PASS}"
  
  if [ -n "${value}" ]
  then
    __import_variable --key "${keyid}" --value "${value}" --use-memory "${YES}"
    return "${PASS}"
  else
    return "${FAIL}"
  fi
}

__check_keyword()
{
  typeset line="$1"
  typeset kw="$2"
  
  [ -z "${line}" ] || [ -z "${kw}" ] && return "${FAIL}"
  [ "${kw}" == ':' ] && return "${FAIL}"
  
  typeset result=$( printf "%s\n" "${line}" | \sed -e "s#[[:space:]]*${kw}[[:space:]]*##" )
  if [ "${result}" != "${line}" ]
  then
    #result="$( __delayed_substitute "${result}" )"
    printf "%s\n" "${result}"
  fi
  return "${PASS}"
}

__check_keyword_on()
{
  typeset line="$1"
  typeset kw="$2"

  [ -z "${line}" ] || [ -z "${kw}" ] && return "${FAIL}"
  [ "${kw}" == ':' ] && return "${FAIL}"

  typeset result=$( printf "%s\n" "${line}" | \sed -e "s#[[:space:]]*${kw}[[:space:]]*##" )
  if [ "${result}" != "${line}" ]
  then
    case "${result}" in
    [yY][eE][sS] | '1' | [tT] | [tT][rR][uU][eE]  ) printf "%d\n" "${YES}";;
    [nN][oO] | '0' | [fF] | [fF][aA][sS][lL][eE]  ) printf "%d\n" "${NO}";;
    *                                             ) printf "%d\n" "${NO}"; return "${FAIL}";;
    esac
  fi
  return "${PASS}"
}

__common_tool_startup()
{
  typeset optfile=
  typeset libfile=
  typeset outdatafile=
  typeset testname_id=

  OPTIND=1
  while getoptex "o: optfile: l: libfile: outdatafile: t: testname-id:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'optfile'      ) optfile="${OPTARG}";;
    'l'|'libfile'      ) libfile="${OPTARG}";;
        'outdatafile'  ) outdatafile="${OPTARG}";;
    't'|'testname-id'  ) testname_id="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Source the generated option file and pull into program
  ###   utilities along with some of the basic library handlers
  ###
  if [ -n "${optfile}" ] && [ -f "${optfile}" ]
  then
    __register_cleanup "${optfile}" inputs
    . "${optfile}"
  fi

  . "${SLCF_SHELL_TOP}/utilities/common/program_utilities.sh"
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source testing shell library component << program_utilities.sh >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  typeset sttm=$( __extract_value 'START_TIME' )

  typeset mslv=$( default_value --def '0.0' "$( __extract_value 'MINIMUM_SHELL_LIBRARY_VERSION' )" )
  typeset version_check=$( printf "%s\n" "$( get_shell_library_version ) >= ${mslv}" | \bc -l )

  if [ ${version_check} -eq ${NO} ]
  then
    printf "\n%s\n\n" "$0 -- Version of support library system is too old ( C:$( get_shell_library_version ) <---> E:${mslv} ).  Exiting!  RC=${NO_LIBRARY_SYSTEM_FOUND}"
    exit "${NO_LIBRARY_SYSTEM_FOUND}"
  fi

  __add_support_binaries

  __register_cleanup "${__FILEMGRFILE}"
  __register_cleanup "$( __extract_value 'LOGFILE' )"

  associate_file_to_channel --channel ERROR --file "$( __extract_value 'LOGFILE' )" --ignore-file-existence --persist
  associate_file_to_channel --channel WARN --file "$( __extract_value 'LOGFILE' )" --ignore-file-existence --persist

  if [ -n "${libfile}" ]
  then
    ###
    ### Here is the beginning of specific code for this tool/application
    ###
    . "$( __extract_value 'STARTUP_DIR' )/../lib/${libfile}"
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source testing component infrastructure << {{TOPLEVEL}}/lib/${libfile} >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
      handle_premature_exit "${optfile}"
      return "$( __extract_value 'EXIT' )"
    fi
  fi

  typeset memopts=$( __define_toplevel_tmpdir )
  eval "${memopts}"

  tpdir="$( __extract_value 'RESULTS_DIR' )"
  [ ! -d "${tpdir}" ] && \mkdir -p "${tpdir}"
  [ ! -d "${tpdir}" ] && exit "$( __extract_value 'EXIT' )"

  [ -n "${testname_id}" ] && __TESTNAME_ID_DEFINED="${testname_id}"
  __TEST_ID_DEFINED=1

  typeset startup_msg='Launched from controlling process...'
  if [ -z "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' 'CANOPUS' )" ]
  then
    startup_msg='Running in stand-alone mode...'
    __set_internal_value 'OUTPUT' "$( __extract_value 'RESULTS_DIR' )/${outdatafile}"
    __set_internal_value 'STAND_ALONE' "${YES}"
  else
    __set_internal_value 'OUTPUT' "$( __extract_value 'TEST_RESULTS_SUBSYSTEM_OUTPUT' 'CANOPUS' )"
  fi
  
  [ $( __check_for --key 'VERBOSE' --success ) -eq "${YES}" ] && print_btf_detail --msg "${startup_msg}" --prefix "$( __extract_value 'PREFIX_INFO' )"

  ###
  ### Display the program header
  ###
  print_program_version "$( __extract_value 'PROGRAM_NAME' )" "$( __extract_value 'PROGRAM_VERSION' ).$( __extract_value 'PROGRAM_VERSION_BUILD' ) ($( __extract_value 'PROGRAM_BUILD_TYPE' ))" "$( __extract_value 'PROGRAM_BUILD_DATE' )"

  ###
  ### Check for expected binaries on this system
  ###
  validate_basic_binaries $( __extract_value 'BASIC_BINARIES' )
  RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to validate necessary base binaries.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  ###
  ### Cache full path instances of these same binaries
  ###
  cache_executables $( __extract_value 'BASIC_BINARIES' )
  RC=$?

  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to cache necessary base binary executable(s).  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optfile}"
    return "$( __extract_value 'EXIT' )"
  fi

  ###
  ### Basic startup information
  ###
  printf "\n"
  print_btf_detail --msg "Starting (UTC)      : $( __change_time_to_UTC ${sttm} )" --prefix "$( __extract_value 'PREFIX_INFO' )"
  print_btf_detail --msg "Temporary Directory : ${tpdir}" --prefix "$( __extract_value 'PREFIX_INFO' )"

  [ -n "$( __extract_value 'INPUT_FILE' )" ] && print_btf_detail --msg "Input Driver File   : $( \readlink "$( __extract_value 'INPUT_FILE' )" )" --prefix "$( __extract_value 'PREFIX_INFO' )"

  print_btf_detail --msg "Output location     : $( __extract_value 'OUTPUT' )" --prefix "$( __extract_value 'PREFIX_INFO' )"
  printf "\n"

  return "${PASS}"
}

__convert_parameter()
{
  typeset param

  OPTIND=1
  while getoptex "p: param:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'param' ) param="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${param}" ] && return "${FAIL}"

  printf "%s\n" "${param}" | \tr "[:lower:]" "[:upper:]" | \tr '-' '_'
  return "${PASS}"
}

__define_internal_variable()
{
  typeset key="$1"
  typeset specialized_variable_prefix="$2"
  
  typeset varname=
  if [ -z "${specialized_variable_prefix}" ]
  then
    [ -z "${__PROGRAM_VARIABLE_PREFIX}" ] && return "${FAIL}"
    varname="${__PROGRAM_VARIABLE_PREFIX}_${key}"
  else
    varname="${specialized_variable_prefix}_${key}"
  fi
  printf "%s\n" "${varname}"
  return "${PASS}"
}

__define_toplevel_tmpdir()
{
  typeset anchor="${1:-'WORKSPACE'}"
  typeset sttm="$( __extract_value 'START_TIME' )"
  [ -z "${sttm}" ] && sttm=$( \date "+%s" )

  typeset data="$( __find_working_directory "${sttm}" "${anchor}" )"
  typeset tpdir="$( printf "%s\n" "${data}" | \cut -f 1 -d '+' )"

  printf "%s\n" "${sttm}+${tpdir}+${memopts}"
  return "${PASS}"
}

__delayed_substitute()
{
  [ $# -lt 1 ] && return "${PASS}"
  
  typeset value="$1"
  typeset RC="${YES}"
  while [ "${RC}" -eq "${YES}" ]
  do
    value="$( __substitute "${value}" )"
    RC=$?
    [ $( __strindex "${value}" '%' ) -gt -1 ] && value="$( printf "%s\n" "${value}" | \sed -e 's#%\(\w*\)%#\$\{\1\}#g' )"
  done
  printf "%s\n" "${value}"
  return "${PASS}"
}

__escapify()
{
  typeset result="$1"
  typeset cycles=${2:-1}
  typeset count=0

  while [ "${count}" -lt "${cycles}" ]
  do
    result=$( printf "%q\n" "${result}" | \sed -e 's/\\/\\\\/g' )
    count=$(( count + 1 ))
  done
  
  printf "%s\n" "${result}"
  return "${PASS}"
}

__evaluate_variable()
{
  typeset value="$1"
  [ -z "${value}" ] && return "${PASS}"
  
  typeset depth="${2:-2}"
  [ "${depth}" -ge 3 ] && value=$( __delayed_substitute "${value}" )
  [ "${depth}" -ge 1 ] && value=$( __internal_substitute "${value}" )  ### Allows for re-use of internal defined variables
  [ "${depth}" -ge 2 ] && value=$( __substitute "${value}" )           ### Allows for pre-defined variables
  
  printf "%s\n" "${value}"
  return "${PASS}"
}

__extract_value()
{
  typeset key="$1"
  typeset specialized_variable_prefix="$2"
  [ -z "${specialized_variable_prefix}" ] && specialized_variable_prefix="${__PROGRAM_VARIABLE_PREFIX}"
  [ -z "${specialized_variable_prefix}" ] && return "${FAIL}"

  typeset varname="$( __define_internal_variable "${key}" "${specialized_variable_prefix}" )"
  if [ $? -eq 0 ] || [ -z "${varname}" ]
  then
    typeset varval=
    eval "varval=\${${varname}}"
    printf "%s\n" "${varval}"
    return "${PASS}"
  else
    return "${FAIL}"
  fi
}

__find_matching_long_parameter()
{
  typeset input="$1"
  typeset searchlist="$2"
  
  [ -z "${searchlist}" ] || [ "${searchlist}" == '[]' ] && return "${FAIL}"
  
  typeset sl
  for sl in ${searchlist}
  do
    typeset shortmatch=$( printf "%s\n" "${sl}" | \cut -f 1 -d ':' )
    if [ "${input}" == "${shortmatch}" ]
    then
      printf "%s\n" "${sl}" | \cut -f 2 -d ':'
      return "${PASS}"
    fi
  done
  printf "%s\n" "${input}"
  return "${FAIL}"
}

__find_working_directory()
{
  typeset starttime="$1"
  typeset anchor="$2"

  typeset memopts=
  typeset tpdir=

  if [ -z "${tpdir}" ]
  then
    if [ -n "${RECURSIVE}" ] && [ "${RECURSIVE}" -gt 0 ]
    then
      tpdir="$( __extract_value 'POSSIBLE_RESULTS_DIR' )"
      if [ -n "${tpdir}" ]
      then
        tpdir+="/${sttm}"
        memopts=$( __import_variable --key "$( __define_internal_variable "${anchor}" )" --value "${tpdir}" --use-memory "${YES}" )
      else
        memopts=$( __import_variable --key "$( __define_internal_variable "${anchor}" )" --value "$( get_temp_dir )/$( get_user_id )/${anchor}/${sttm}" --use-memory "${YES}" )
      fi
    else
      typeset grpdir="$( __extract_value 'GROUP_DIR' )"
      if [ -z "${grpdir}" ]
      then
        memopts=$( __import_variable --key "$( __define_internal_variable "${anchor}" )" --value "$( get_temp_dir )/$( get_user_id )/${anchor}/${sttm}" --use-memory "${YES}" )
      else
        memopts=$( __import_variable --key "$( __define_internal_variable "${anchor}" )" --value "$( get_temp_dir )/$( get_user_id )/${grpdir}/${sttm}" --use-memory "${YES}" )
      fi
    fi
  else
    memopts=$( __import_variable --key "$( __define_internal_variable "${anchor}" )" --value "${tpdir}" --use-memory "${YES}" )
  fi

  memopts+=$( __import_variable --key "$( __define_internal_variable "${__PROGRAM_VARIABLE_PREFIX}_ACTIVE" )" --value '1' --use-memory "${YES}" )
  eval "${memopts}"

  tpdir="$( __extract_value 'WORKSPACE' )"
  [ ! -d "${tpdir}" ] && \mkdir -p "${tpdir}"
  [ ! -d "${tpdir}" ] && exit "$( __extract_value 'EXIT' )"      

  printf "%s\n" "${tpdir}+${memopts}"
  return "${PASS}"
}

__get_library_attribute()
{
  typeset library_name="$1"
  typeset attr="${2:-Version}"

  if [ -z "${library_name}" ] || [ ! -f "${library_name}" ]
  then
    return "${FAIL}"
  fi

  \cat "${SLCF_SHELL_TOP}/lib/${library_name}.sh" | \grep -i "## @${attr}" | \cut -f 2 -d ':' | \sed -e 's/^[[:blank:]]*//' -e 's/[[:blank:]]*$//'
  return "${PASS}"
}

__handle_spaced_output()
{
  typeset input="$1"
  typeset direction="${2:-0}"
  shift $#
  
  typeset space_marker="$( __extract_value 'SPACE_MARKER' $@ )"
  if [ -n "${input}" ]
  then
    if [ "${direction}" -eq 0 ]
    then
      trim "${input}" | \sed -e "s# #${space_marker}#g"
    else
      printf "%s\n" "${input}" | \sed -e "s#${space_marker}# #g"
    fi
  fi
  return "${PASS}"
}

__ignore_lines()
{
  typeset line="$1"
  typeset expressions="$2"
  
  if [ -z "${line}" ]
  then
    printf "%d\n" "${YES}"
    return "${PASS}"
  fi
  
  typeset grepexp
  for grepexp in ${expressions}
  do
    printf "%s\n" "${line}" | \grep -q "${grepexp}"
    if [ $? -eq "${PASS}" ]
    then
      printf "%d\n" "${NO}"
      return "${PASS}"
    fi 
  done
  
  printf "%d\n" "${YES}"
  return "${PASS}"
}

__import_all_variables()
{
  typeset USE_MEMORY="${NO}"
  typeset filename=
  typeset envvar
  
  OPTIND=1
  while getoptex "use-memory. f: file:" "$@"
  do
    case "${OPTOPT}" in
        'use-memory' ) USE_MEMORY="${OPTARG:-${YES}}";;
    'f'|'file'       ) filename="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${filename}" ]
  then
    if [ "${USE_MEMORY}" -eq "${NO}" ]
    then
      [ -z "${__PROGRAM_OPTION_FILE}" ] && return "${FAIL}"
      filename="${__PROGRAM_OPTION_FILE}"
    fi
  fi
  
  for envvar in $@
  do
    if [ -n "${filename}" ]
    then
      __import_variable --key "${envvar}" --env --use-memory "${NO}" --file "${filename}"
    else
      __import_variable --key "${envvar}" --env --use-memory "${YES}"
    fi
  done
  return "${PASS}"
}

__import_variable()
{
  typeset option=
  typeset option_result=
  typeset get_from_env="${NO}"
  typeset USE_MEMORY="${NO}"
  typeset fileout="${__PROGRAM_OPTION_FILE}"
  typeset GRAB_FROM_ENVIRONMENT="${NO}"
  
  OPTIND=1
  while getoptex "env key: value. f: file: use-memory." "$@"
  do
    case "${OPTOPT}" in
        'use-memory' ) USE_MEMORY="${OPTARG}"; [ -z "${USE_MEMORY}" ] && USE_MEMORY="${NO}";;
        'env'        ) GRAB_FROM_ENVIRONMENT="${YES}";;
        'key'        ) option="${OPTARG}";;
        'value'      ) option_result="${OPTARG}";;
    'f'|'file'       ) fileout="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${option}" ] && return "${FAIL}"
  
  if [ "${GRAB_FROM_ENVIRONMENT}" -eq "${YES}" ]
  then
    eval "option_result=\$${option}"
  fi
  
  option=$( printf "%s\n" "${option}" | \tr "[:lower:]" "[:upper:]" )
  [ -n "${option_result}" ] && option_result=$( printf "%s\n" "${option_result}" | \sed -e "s#['\"]##g" )
  
  if [ "${USE_MEMORY}" -eq "${NO}" ]
  then
    [ -n "${fileout}" ] && printf "%s\n" "${option}='${option_result}'" "export ${option}" >> "${fileout}"
  else
    printf "%s\n" "${option}='${option_result}'; export ${option};"
  fi
  return "${PASS}"
}

__initialize_program_utilities()
{
  if [ -z "${__SLCF_ARGPARSING_ERROR_LOG}" ]
  then
    . "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
    . "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  fi
  return "${PASS}"
}

__internal_substitute()
{
  typeset input="$1"
  shift
  [ -z "${input}" ] && return "${FAIL}"
  
  input="$( printf "%s\n" "${input}" | \sed -e "s#['\"]##g" )"

  typeset rebuilt_input
  typeset word
  for word in ${input}
  do
    typeset newword="$( __replace_enclosed '${' '}' "${word}" "${YES}" )"
    if [ $( is_empty --str "${newword}" ) -eq "${YES}" ]
    then
      newword="$( __replace_enclosed '${' '}' "${word}" "${NO}" "${NO}" )"
    fi
    if [ "${newword}" != "${word}" ]
    then
      typeset define_newword="$( __define_internal_variable "${newword}" $@ )"
      #typeset match="$( \sed -n "#\b${define_newword}\b#p" "${__PROGRAM_OPTION_FILE}" | \grep -v 'export' )"
      typeset match="$( \grep "\b${define_newword}=" "${__PROGRAM_OPTION_FILE}" | \grep -v 'export' )"
      if [ -n "${match}" ]
      then
        typeset key=$( printf "%s\n" "${match}" | \cut -f 1 -d '=' )
        typeset replace_value=$( printf "%s\n" "${match}" | \cut -f 2 -d '=' | \sed -e "s#['\"]##g" )
        rebuilt_input+="${replace_value} "
      else
        rebuilt_input+="${word} "
      fi
    else
      rebuilt_input+="${word} "
    fi
  done
  
  [ -n "${rebuilt_input}" ] && printf "%s\n" "${rebuilt_input}" | \sed -e 's# $##'
  return "${PASS}"
}

__make_tab_level()
{
  typeset level=0

  OPTIND=1
  while getoptex "l: level:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'level' ) level="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${level}" -lt 0 ] && level=0
  [ "${level}" -eq 0 ] && return "${PASS}"
  
  typeset varval=$( __extract_value 'DISPLAY_TAB_MARKER' )
  [ -z "${varval}" ] && varval=$'\t'

  level=$( printf '%*s' "${level}" | \tr ' ' "|" | \sed -e "s#|#${varval}#g" )
  printf "%s\n" "${level}"
  return "${PASS}"
}

__option_manager()
{
  typeset SHORT_SINGLE_OPTIONS="$1"
  typeset SHORT_MULTI_OPTIONS="$2"
  typeset SINGLE_OPTIONS="$3"
  typeset MULTI_OPTIONS="$4"
  typeset SHORT_OPTION_MATCHES="$5"
  shift 5
  
  typeset SO=
  [ -n "${SHORT_SINGLE_OPTIONS}" ] && [ "${SHORT_SINGLE_OPTIONS}" != '[]' ] && SO+=" ${SHORT_SINGLE_OPTIONS}"
  [ -n "${SHORT_MULTI_OPTIONS}" ] && [ "${SHORT_MULTI_OPTIONS}" != '[]' ] && SO+=" ${SHORT_MULTI_OPTIONS}"
  
  typeset LO=
  [ -n "${SINGLE_OPTIONS}" ] && [ "${SINGLE_OPTIONS}" != '[]' ] && LO+=" ${SINGLE_OPTIONS}"
  [ -n "${MULTI_OPTIONS}" ] && [ "${MULTI_OPTIONS}" != '[]' ] && LO+=" ${MULTI_OPTIONS}"
  
  typeset fileout_opts=
  typeset fileout="$( __extract_value 'OPTION_FILE' )"
  [ -n "${fileout}" ] && fileout_opts="--file ${fileout}"

  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_RECORDER_STARTING" --value 'Starting' ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_RECORDER_STOPPING" --value 'Completed' ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_SHORT_OPTIONS" --value "${SO}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_LONG_OPTIONS" --value "${LO}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_PROGRAM_OPTIONS" --value "${SO} ${LO}" ${fileout_opts}
  
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_SHORT_SINGLE_OPTIONS" --value "${SHORT_SINGLE_OPTIONS}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_SHORT_MULTI_OPTIONS" --value "${SHORT_MULTI_OPTIONS}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_SINGLE_OPTIONS" --value "${SINGLE_OPTIONS}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_MULTI_OPTIONS" --value "${MULTI_OPTIONS}" ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_SHORT_OPTION_MATCHES" --value "${SHORT_OPTION_MATCHES}" ${fileout_opts}

  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_STATIC_OVERHEAD" --value 0 ${fileout_opts}
  __import_variable --key "${__PROGRAM_VARIABLE_PREFIX}_DYNAMIC_OVERHEAD" --value 0 ${fileout_opts}
  
  ###
  ### Hack to ensure all commandline args get passed
  ###
  typeset args="$@"
  __setup_program "${SHORT_SINGLE_OPTIONS}" "${SHORT_MULTI_OPTIONS}" "${SINGLE_OPTIONS}" "${MULTI_OPTIONS}" "${SHORT_OPTION_MATCHES}" ${args}
  return "${PASS}"

}

__process_spo_match()
{
  typeset input="$1"
  typeset conversion_set="$2"
  typeset result="$3"
  shift 3
  
  typeset param_match=$( __find_matching_long_parameter "${input}" "${conversion_set}" )
  typeset varname="$( __define_internal_variable "$( __convert_parameter --param "${param_match}" )" )"

  typeset ktfp="${varname}"
  
  [ -z "${ktfp}" ] && return "${FAIL}"
  
  eval "${ktfp}=${result:-${YES}}"
  
  printf "%s\n" "${ktfp}"
  return "${PASS}"
}

###
### Mechanism to register file to be moved
###
__register_cleanup()
{
  typeset input="$1"
  typeset location="${2:-outputs}"
  typeset outputdir="$3"
  
  ###
  ### Need to have a means to abstract this away in the event RESULTS_DIR is not set...
  ###
  typeset depositdir=
  typeset tpdir="$( __extract_value 'RESULTS_DIR' )"
  [ -z "${input}" ] && return "${FAIL}"
  if [ -z "${tpdir}" ] || [ ! -d "${tpdir}" ]
  then
    [ -z "${outputdir}" ] || [ ! -d "${outputdir}" ] && return "${FAIL}"
    depositdir="${outputdir}"
  else
    depositdir="${tpdir}"
  fi

  if [ -f "${depositdir}/.cleanup" ]
  then
    \cat "${depositdir}/.cleanup" | \grep -q "${input}"
    [ $? -ne 0 ] && [ "${location}" != '<SKIP>' ] && printf "%s\n" "${input}:${location}" >> "${depositdir}/.cleanup"
  else
    [ "${location}" != '<SKIP>' ] && printf "%s\n" "${input}:${location}" >> "${depositdir}/.cleanup"
  fi
  return "${PASS}"
}

__replace_enclosed()
{
  typeset leftside="$1"
  typeset rightside="$2"
  typeset value="$3"
  typeset run_eval="${4:-${NO}}"
  typeset re_encode="${5:-${YES}}"
  
  typeset return_code=2
  
  [ -z "${value}" ] && return "${return_code}"
  if [ -z "${leftside}" ] || [ -z "${rightside}" ]
  then
    printf "%s\n" "${value}"
    return "${return_code}"
  fi
  
  typeset leftlen=${#leftside}
  typeset rightlen=${#rightside}
  
  typeset left=$( __strindex "${value}" "${leftside}" )
  typeset right=$( __strindex "${value}" "${rightside}" )
  
  if [ "${left}" -ne -1 ] && [ "${right}" -ne -1 ]
  then
    left=$(( left + ${leftlen} - 1 ))
    typeset diff=$(( right - left - rightlen ))
    typeset match="${value:${left}:${diff}}"
    if [ "${run_eval}" -eq "${YES}" ]
    then
      eval "eval_match=\${$match}"
      value=$( printf "%s\n" "${value}" | \sed -e s"#${leftside}$match${rightside}#${eval_match}#" )
    else
      if [ "${re_encode}" -eq "${YES}" ]
      then
        value="\${${match}}"
      else
        value="${match}"
      fi
    fi
   return_code="${YES}"
  fi
  
  printf "%s\n" "${value}"
  return "${return_code}"
}

__set_internal_value()
{
  typeset key="$1"
  typeset value="$2"
  typeset specialized_variable_prefix="$3"
  
  [ -z "${specialized_variable_prefix}" ] && specialized_variable_prefix="${__PROGRAM_VARIABLE_PREFIX}"
  [ -z "${specialized_variable_prefix}" ] && return "${FAIL}"
  [ -z "${key}" ] && return "${FAIL}"
  
  typeset varname="$( __define_internal_variable "${key}" "${specialized_variable_prefix}" )"
  if [ -n "${value}" ]
  then
    eval "${varname}='${value}'"
  else
    eval "${varname}="
  fi
  return "${PASS}"
}

__set_option_file()
{
  [ $# -lt 1 ] && return 1
  __PROGRAM_OPTION_FILE="$1"
  return "${PASS}"
}

__set_program_variable_prefix()
{
  [ $# -lt 1 ] && return 1
  __PROGRAM_VARIABLE_PREFIX="$1"
  return "${PASS}"
}

###
### Needs to provide a handle to binary specific setup.
###
__setup_paths()
{
  [ $# -lt 1 ] || [ -z "$1" ] && return "${FAIL}"
  
  typeset exported_vars=''
  typeset RC=

  __set_internal_value 'EXIT' 252

  ###
  ### Related SLCF directory structure
  ###
  SLCF_SHELL_TOP="$1"
  SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
  SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
  SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  SLCF_SHELL_LIBDIR="${SLCF_SHELL_FUNCTIONDIR}"
  
  __START_TIME="$2"  ### Used by base_logging to re-use a predetermined time coordinate
  __set_internal_value 'START_TIME' "$2"

  if [ -f "${SLCF_SHELL_TOP}/lib/argparsing.sh" ]
  then
    . "${SLCF_SHELL_TOP}/lib/argparsing.sh"
    [ $? -ne 0 ] && return "$( __extract_value 'EXIT' )"
  else
    printf "\n%s\n\n" "Unable to find necessary basic functional library << argparsing >>"
    return "$( __extract_value 'EXIT' )"
  fi
  
  if [ -z "$4" ]
  then
    __set_option_file "$( __extract_value 'STARTUP_DIR' )/.options_$2.sh"
  else
    __set_option_file "$4/.options_$2.sh"
  fi
  
  __set_internal_value 'OPTION_FILE' "${__PROGRAM_OPTION_FILE}"
  
  ###
  ### Export necessary SLCF variables into the environment so subshells can have access to them
  ###
  exported_vars+='SLCF_SHELL_TOP SLCF_SHELL_LIBDIR SLCF_SHELL_RESOURCEDIR SLCF_SHELL_FUNCTIONDIR SLCF_SHELL_UTILDIR '
  typeset fd=
  for fd in ${exported_vars}
  do
    typeset evaldf_fd
    eval "evald_fd=\"\${${fd}}\""
    [ ! -d "${evald_fd}" ] && return "$( __extract_value 'EXIT' )"
  done
  
  exported_vars+="$( __define_internal_variable 'OPTION_FILE' ) $( __define_internal_variable 'EXIT' ) $( __define_internal_variable 'START_TIME' ) "
  
  ###
  ### Display Management settings
  ###
  __set_internal_value 'DISPLAY_TAB_MARKER' '@@@'
  __set_internal_value 'DISPLAY_NEWLINE_MARKER' '|||'

  exported_vars+="$( __define_internal_variable 'DISPLAY_TAB_MARKER' ) $( __define_internal_variable 'DISPLAY_NEWLINE_MARKER' ) "
  
  __set_internal_value 'DEFAULT_DETAIL_PREFIX' '-->'
  __set_internal_value 'DEFAULT_BLANK_LINE' "printf \"\\\n\""

  exported_vars+="$( __define_internal_variable 'DEFAULT_DETAIL_PREFIX' ) $( __define_internal_variable 'DEFAULT_BLANK_LINE' ) "

  __set_internal_value 'DETAIL_PREFIX' "$( __extract_value 'DEFAULT_DETAIL_PREFIX' )"
  __set_internal_value 'BLANK_LINE' "$( __extract_value 'DEFAULT_BLANK_LINE' )"
  __set_internal_value 'DIVIDER' '------------------------------------------------------------------'
  __set_internal_value 'DBL_DIVIDER' '=================================================================='
  
  exported_vars+="$( __define_internal_variable 'DETAIL_PREFIX' ) $( __define_internal_variable 'BLANK_LINE' ) $( __define_internal_variable 'DIVIDER' ) $( __define_internal_variable 'DBL_DIVIDER' ) "

  ###
  ### Returns all necessary variables into an options file
  ###
  __import_all_variables "${exported_vars}"

  ###
  ### Allow for program specific setup necessary
  ###
  RC="${PASS}"
  if [ -n "$3" ]
  then
    . "$3"
    RC=$?
  fi
  return "${RC}"
}

__setup_program()
{
  typeset short_single_program_options="$1"
  [ "${short_single_program_options}" == '[]' ] && short_single_program_options=
  shift

  typeset short_multi_program_options="$1"
  [ "${short_multi_program_options}" == '[]' ] && short_multi_program_options=
  shift
  
  typeset single_program_options="$1"
  [ "${single_program_options}" == '[]' ] && single_program_options=
  shift
  
  typeset multi_program_options="$1"
  [ "${multi_program_options}" == '[]' ] && multi_program_options=
  shift

  typeset short_2_long_matching="$1"
  [ "${short_2_long_matching}" == '[]' ] && short_2_long_matching=
  shift

  typeset args="$@"
  
  typeset USE_MEMORY="${NO}"
  typeset options_in_memory=

  typeset RC="${PASS}"
  typeset ktfp=
  typeset varval=

  ###
  ### Clears the contents from the commandline option perspective
  ### 
  for ktfp in ${single_program_options} ${multi_program_options}
  do
    typeset orig_ktfp=$( printf "%s\n" "${ktfp}" | \sed -e 's#[:;.]$##' )      
    ktfp="$( __define_internal_variable "$( __convert_parameter --param "${orig_ktfp}" )" )"
    if [ "${ktfp}" != 'use-memory' ]
    then
      typeset result
      eval "result=\$${ktfp}"
      [ -z "${result}" ] && eval "${ktfp}="
    fi
  done

  ###
  ### Clears the contents from the commandline option perspective
  ### 
  for ktfp in ${short_single_program_options} ${short_multi_program_options}
  do
    typeset orig_ktfp=$( printf "%s\n" "${ktfp}" | \sed -e 's#[:;.]$##' )
    typeset param_match=$( __find_matching_long_parameter "${orig_ktfp}" "${short_2_long_matching}" )
    if [ -n "${param_match}" ]
    then
      ktfp="$( __define_internal_variable "$( __convert_parameter --param "${param_match}" )" )"
    else
      ktfp="$( __define_internal_variable "SHORT_OPTION_$( __convert_parameter --param "${orig_ktfp}" )" )"
    fi
    if [ "${ktfp}" != 'use-memory' ]
    then
      typeset result
      eval "result=\$${ktfp}"
      [ -z "${result}" ] && eval "${ktfp}="
    fi
  done

  __set_internal_value 'INTERNAL_DISPLAY' "${NO}"
  __set_internal_value 'USER_DATA' "${NO}"
  __set_internal_value 'HELP' "${NO}"

  typeset expanded_parameters="${single_program_options} ${multi_program_options} ${short_single_program_options} ${short_multi_program_options} help. load-userdata: usage use-memory h. ? D: define:"
  expanded_parameters="$( printf "%s\n" ${expanded_parameters} | \sort | \uniq | \tr '\n' ' ' | \sed -e 's#[[:blank:]]*$##' )"

  typeset help_screens=
  
  OPTIND=1
  while getoptex "${expanded_parameters}" ${args}
  do
    ### See if the option matches a single setting option
    typeset spo_match=$( match_program_options "${single_program_options} help load-userdata usage" "${OPTOPT}" )

    ### See if the option matches a multiple setting option
    typeset mpo_match=$( match_program_options "${multi_program_options}" "${OPTOPT}" )
    
    typeset sh_spo_match=$( match_program_options "${short_single_program_options} ? h D" "${OPTOPT}" )
    typeset sh_mpo_match=$( match_program_options "${short_multi_program_options}" "${OPTOPT}" )
    
    ### If the option is found in both (single and multi) option lists, choose the single
    ###   option list to assign
    [ "${spo_match}" -eq "${YES}" ] && [ "${mpo_match}" -eq "${YES}" ] && mpo_match="${NO}"
    [ "${sh_spo_match}" -eq "${YES}" ] && [ "${sh_mpo_match}" -eq "${YES}" ] && sh_mpo_match="${NO}"

    ### If option is not found in either single or multi option list
    ###   (i.e. is not a supported option) then we will set the HELP flag and
    ###   exit the loop to go to the help screen as soon as possible
    if [ "${spo_match}" -ne "${YES}" ] && [ "${mpo_match}" -ne "${YES}" ] && [ "${sh_spo_match}" -ne "${YES}" ] && [ "${sh_mpo_match}" -ne "${YES}" ]
    then
      __set_internal_value 'HELP' "${YES}"
      break
    fi

    ###
    ### Deal with complex command line options (multi option case)
    ###
    if [ "${mpo_match}" -eq "${YES}" ] || [ "${sh_mpo_match}" -eq "${YES}" ]
    then
      if [ "${sh_mpo_match}" -eq "${YES}" ]
      then
        typeset param_match=$( __find_matching_long_parameter "${OPTOPT}" "${short_2_long_matching}" )
        ktfp="$( __convert_parameter --param "${param_match}" )"
      else
        ktfp="$( __convert_parameter --param "${OPTOPT}" )"
      fi
      __addto_internal_variable "${ktfp}" "${OPTARG}"
      continue
    fi
    
    ###
    ### Deal with complex command line options (single option case)
    ###
    typeset definekey=
    typeset defineval=
    typeset process="${NO}"
    
    ### --> TODO  : Need a way to save the defines so they can be recorded as properties when needed
    if [ "${spo_match}" -eq "${YES}" ] || [ "${sh_spo_match}" -eq "${YES}" ]
    then
      case "${OPTOPT}" in
      'load-userdata'         ) __set_internal_value 'USER_DATA' "${YES}"; __set_internal_value 'USER_DATA_FILE' "${OPTARG}"; continue;;
      'h'|'help'|'usage'      ) __set_internal_value 'HELP' "${YES}"; if [ -n "${OPTARG}" ]; then help_screens+=" ${OPTARG}"; else help_screens='?'; fi; continue;;
      '?'                     ) __set_internal_value 'HELP' "${YES}"; help_screens='?'; continue;;
      'D'|'define'            ) definekey="$( printf "%s\n" "${OPTARG}" | \cut -f 1 -d '=' )"; defineval="$( printf "%s\n" "${OPTARG}" | \cut -f 2 -d '=' )"; eval "${definekey}=\"${defineval}\"";;
      *                       ) process="${YES}";;
      esac
    fi

    if [ -n "${definekey}" ]
    then
      eval "options_in_memory+=\$( __import_variable --key \"${definekey}\" --value \"${defineval}\" --use-memory \"${USE_MEMORY}\" )"
      continue
    fi

    if [ "${process}" -eq "${YES}" ]
    then
      if [ -n "${short_2_long_matching}" ]
      then
        ktfp="$( __process_spo_match "${OPTOPT}" "${short_2_long_matching}" "${OPTARG}" )"
        RC=$?
        if [ "${RC}" -ne "${PASS}" ]
        then
          __set_internal_value 'HELP' "${YES}"
          continue
        else
          [ -z "${OPTARG}" ] && OPTARG="${YES}"
          eval "options_in_memory+=\$( __import_variable --key \"${ktfp}\" --value \"${OPTARG}\" --use-memory \"${USE_MEMORY}\" )"
        fi
      else
        [ -z "${OPTARG}" ] && OPTARG="${YES}"
        eval "options_in_memory+=\$( __import_variable --key \"${ktfp}\" --value \"${OPTARG}\" --use-memory \"${USE_MEMORY}\" )"
      fi
    fi
  done

  help_screens="$( trim "${help_screens}" )"
  printf "%s\n" ${help_screens} | \grep -q '?'
  [ $? -eq 0 ] && help_screens=

  ###
  ### Automatic specifications
  ###
  typeset sys_data_file="$( __extract_value 'SYSTEM_DATA_FILE' )"
  [ -n "${sys_data_file}" ] && [ -f "${sys_data_file}" ] && options_in_memory+=$( process_data --filename "${sys_data_file}" --use-memory "${USE_MEMORY}" )

  typeset user_data_file="$( __extract_value 'USER_DATA_FILE' )"
  [ "$( __extract_value 'USER_DATA' )" -eq "${YES}" ] && options_in_memory+=$( process_data --filename "${user_data_file}" --use-memory "${USE_MEMORY}" )
  [ "${OPTRET}" -ne "${PASS}" ] || [ -n "${OPTERR}" ] && __set_internal_value 'HELP' "${YES}"

  if [ "${OPTRET}" -ne "${PASS}" ]
  then
    varval="$( __extract_value 'HELP' )"
    printf "%s\n" "@$@@${varval}|${help_screens}@Error message --> \"${OPTERR}\"" | \sed -e 's#[[:blank:]]*$##' | \tr '\n' ' '
  else
    shift $(( OPTIND-1 ))
  
    for ktfp in ${single_program_options} ${multi_program_options}
    do
      typeset orig_ktfp=$( printf "%s\n" "${ktfp}" | \sed -e 's#[:;.]$##' )
      ktfp="$( __define_internal_variable "$( __convert_parameter --param "${orig_ktfp}" )" )"
      if [ "${orig_ktfp}" != 'use-memory' ]
      then
        ### See if the option matches a multiple setting option
        typeset mpo_match=$( match_program_options "${multi_program_options}" "${orig_ktfp}" )
        
        if [ "${mpo_match}" -eq "${YES}" ]
        then
          eval "option_result=\"\${$ktfp}\""
          if [ -n "${option_result}" ]
          then
            eval "options_in_memory+=\$( __import_variable --key "${ktfp}" --value "\"${option_result}\"" --use-memory "${USE_MEMORY}" )"
          fi
        else
          eval "option_result=\${$ktfp}"
          if [ -n "${option_result}" ]
          then
            eval "options_in_memory+=\$( __import_variable --key "${ktfp}" --value "${option_result}" --use-memory "${USE_MEMORY}" )"
          fi
        fi
      fi
    done
    varval="$( __extract_value 'HELP' )"
    typeset result="$( trim "${options_in_memory}@$( printf "%s\n" "$@" | \tr '\n' ' ' | \tr ' ' '|' )@${varval}|${help_screens}@" )"
    printf "%s\n" "${result}"
    #printf "%s\n" "${options_in_memory}@$( printf "%s\n" "$@" | tr '\n' ' ' | tr ' ' '|' )@${SLCF_HELP}|${help_screens}@" | sed -e 's#[[:blank:]]*$##' >> /tmp/.xyz
  fi
  return "${PASS}"
}

__strindex()
{
  if [ $# -lt 2 ]
  then
    printf "%d\n" -1
  else
    typeset x="${1%%$2*}"
    if [ "${x}" == "$1" ]
    then
      printf "%d\n" -1
    else
      printf "%d\n" $(( ${#x} + 1 ))
    fi
  fi
  return "${PASS}"
}

__substitute()
{
  [ $# -lt 1 ] && return "${PASS}"
  
  typeset value="$1"
  typeset RC="${YES}"
  while [ "${RC}" -eq "${YES}" ]
  do
    value="$( __replace_enclosed '${' '}' "${value}" "${YES}" )"
    RC=$?
  done
  
  printf "%s\n" "${value}"
  return "${PASS}"
}

__update_overhead()
{
  typeset style="$1"
  typeset btime="$2"
  typeset etime="$3"
  
  typeset dtime=$(( etime - btime ))
  typeset value=
  
  eval "value=\$( default_value --def 0 \${${__PROGRAM_VARIABLE_PREFIX}_${style}_OVERHEAD} )"
  eval "${__PROGRAM_VARIABLE_PREFIX}_${style}_OVERHEAD=\$(( ${value} + ${dtime} ))"
  eval "value=\${${__PROGRAM_VARIABLE_PREFIX}_${style}_OVERHEAD}"
  
  eval "${__PROGRAM_VARIABLE_PREFIX}_TIMESTAMP=${etime}"
  return "${PASS}"
}

__update_dynamic_overhead()
{
  typeset btime="$1"
  typeset etime="$2"
  
  if [ -z "${btime}" ] || [ -z "${etime}" ]
  then
    [ -n "$( __extract_value 'DYNAMIC_OVERHEAD' )" ] && printf "%d\n" "$( __extract_value 'DYNAMIC_OVERHEAD' )"
    return "${FAIL}"
  else
    __update_overhead 'DYNAMIC' "${btime}" "${etime}"
    return $?
  fi
}

__update_static_overhead()
{
  typeset btime="$1"
  typeset etime="$2"
  
  if [ -z "${btime}" ] || [ -z "${etime}" ]
  then
    [ -n "$( __extract_value 'STATIC_OVERHEAD' )" ] && printf "%d\n" "$( __extract_value 'STATIC_OVERHEAD' )"
    return "${FAIL}"
  else
    __update_overhead 'STATIC' "${btime}" "${etime}"
    return $?
  fi
}

cache_executables()
{
  __debug $@

  [ -z "${NO_EXECUTABLE_FOUND}" ] && NO_EXECUTABLE_FOUND=10
  
  type "__has_installed" 2>/dev/null | \grep -q 'is a function'
  if [ $? -eq 0 ]
  then
    [ $( __has_installed execaching ) -eq "${NO}" ] && . "${SLCF_SHELL_TOP}/lib/execaching.sh"
    [ $( __has_installed logging ) -eq "${NO}" ] && . "${SLCF_SHELL_TOP}/lib/logging.sh"
  else
    exit "${NO_EXECUTABLE_FOUND}"
  fi
  
  typeset b=
  for b in $@
  do
    typeset execache=
    eval "execache=\${${b}_exe}"
    if [ -z "${execache}" ]
    then
      make_executable --exe "${b}"
      eval "execache=\${${b}_exe}"
      if [ -z "${execache}" ]
      then
        print_msg --msg "Unable to find executable << ${b} >>" --errorcode "${NO_EXECUTABLE_FOUND}" --type 'ERROR' --errorcode "${NO_EXECUTABLE_FOUND}"
        exit "${NO_EXECUTABLE_FOUND}"
      fi
    fi
  done
  return "${PASS}"
}

display_cached_executables()
{
  __debug $@

  printf "\n"
  typeset b=
  for b in $@
  do
    typeset execache=
    eval "execache=\${${b}_exe}"
    print_btf_detail --msg "Cached executable path for << ${b} >> --> << ${execache} >>"
  done
  return "${PASS}"
}

display_cmdline_flags()
{
  typeset program_options="$@"
  typeset found=0
  typeset ktfp=

  typeset quiet_failure="$( __check_for --key 'QUIET' --failure )"
  
  for ktfp in ${program_options}
  do
    typeset orig_ktfp="${ktfp}"
    typeset option_result=

    ktfp="$( __convert_parameter --param "${ktfp}" )"
    typeset lastchar="${ktfp:$((${#ktfp}-1)):1}"
    [ "${lastchar}" == ';' ] || [ "${lastchar}" == ':' ] && continue
    
    option_result="$( __extract_value "${ktfp}" )"

    if [ -n "${option_result}" ] && [ "${option_result}" -ne 0 ]
    then
      [ "${quiet_failure}" -eq "${YES}" ] && print_btf_detail --msg "{ ${ktfp} } setting : ENABLED"
      found=$(( found + 1 ))
    fi
  done

  [ "${found}" -ge 1 ] && [ "${quiet_failure}" -eq "${YES}" ] && printf "\n"
  return "${PASS}"
}

gather_timestamp()
{
  \date "+%m-%d-%Y %H:%M:%S [%s]"
  return "${PASS}"
}

get_environment()
{
  typeset env_vars=
  typeset remove_program_envvars="${YES}"

  while getoptex "f full" "$@"
  do
    case "${OPTOPT}" in
    'f'|'full' ) remove_program_envvars="${NO}";;
    esac
  done
  shift $(( OPTIND-1 ))

  env_vars="$( \env | \sort )"
  if [ "${remove_program_envvars}" -eq "${YES}" ]
  then
    env_vars="$( printf "%s\n" ${env_vars} )"
    if [ -n "^${__PROGRAM_VARIABLE_PREFIX}" ]
    then
      env_vars="$( printf "%s\n" ${env_vars} | \grep -v "${__PROGRAM_VARIABLE_PREFIX}" )"
    fi
  fi

  printf "%s " ${env_vars}
  return "${PASS}"
}

get_shell_library_version()
{
  if [ -f "${SLCF_SHELL_TOP}/version" ]
  then
    typeset ver=
    if [ $# -gt 0 ]
    then
      ver=$( \cat "${SLCF_SHELL_TOP}/version" | \cut -f 1-2 -d '.' )
    else
      ver=$( \cat "${SLCF_SHELL_TOP}/version" )
    fi
    printf "%s\n" "${ver}"
  else
    printf "%s\n" '0.00'
  fi
  return "${PASS}"
}

handle_error_output()
{
  handle_output --prefix-type 'ERROR' "$@"
  return "${PASS}"
}

handle_output()
{
  typeset write_to_screen="${YES}"

  typeset msg=
  typeset prefix_type=
  typeset channels=

  OPTIND=1
  while getoptex "m: msg: message: p: prefix-type: no-screen c: channel:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'msg'|'message'  ) msg="${OPTARG}";;
    'p'|'prefix-type'    ) prefix_type="${OPTARG}";;
        'no-screen'      ) write_to_screen="${NO}";;
    'c'|'channel'        ) channels+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${msg}" ] && return "${PASS}"

  case $( to_upper "${prefix-type}" ) in
  'ERROR'           )   channels+=' ERROR';;
  'WARN'|'WARNING'  )   channels+=' WARN'; prefix_type='WARN';;
  esac

  if [ "${write_to_screen}" -eq "${YES}" ]
  then
    print_btf_detail --msg "${msg}" --prefix "$( __extract_value "PREFIX_${prefix_type}" )" $@
  fi

  channels=$( printf "%s\n" ${channels} | \sort | \uniq )

  typeset channel_opts=
  typeset c=
  for c in ${channels}
  do
    channel_opts+=" --channel '${c}'"
  done
  
  append_output --data "${msg}" ${channel_opts}
  return "${PASS}"
}

###
### Settings for premature exiting
###
handle_premature_exit()
{
  __set_internal_value 'PREMATURE_EXIT' 1
  store_generated_output $@
  return "${PASS}"
}

handle_warning_output()
{
  handle_output --prefix-type 'WARN' "$@"
  return "${PASS}"
}

help_banner()
{
  typeset input="$1"
  [ -z "${input}" ] && return "${PASS}"
  
  typeset newline_marker="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"

  typeset menu
  typeset banner_wrapper="$( \awk -v count=${#input} 'BEGIN { while (i++ < count) printf "=" }' )"

  menu+=$( printf "%s" "${banner_wrapper}${newline_marker}" )
  menu+=$( printf "%s" "${input}${newline_marker}" )
  menu+=$( printf "%s" "${banner_wrapper}${newline_marker}${newline_marker}" )

  printf "%s" "${menu}"
  return "${PASS}"
}

load_program_library()
{
  typeset input_lib="$1"
  typeset optionfile="$2"
  
  [ -z "${optionfile}" ] || [ ! -f "${optionfile}" ] && return "${FAIL}"
  . "${input_lib}"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    __set_internal_value 'PREMATURE_EXIT_MSG' "Unable to properly source testing component infrastructure << $( \basename "${input_lib}" ) >>.  Exiting!$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
    handle_premature_exit "${optionfile}"
    return "$( __extract_value 'EXIT' )"
  fi
  return "${PASS}"
}

log_error()
{
  append_output --channel 'ERROR' --data "$1"
  return $?
}

log_warning()
{
  append_output --channel 'WARN' --data "$1"
  return $?
}

match_program_options()
{
  typeset program_options="$1"
  typeset opt="$2"
  [ "${program_options}" == '[]' ] && program_options=
  shift
  
  if [ -z "${program_options}" ]
  then
    print_no
    return "${PASS}"
  fi
  
  typeset process_list=$( printf "%s\n" ${program_options} | \awk -F '[:;.]' '{print $1}' )
  printf "%s\n" "${process_list}" | \grep -q "\b${opt}\b"
  typeset RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

print_btf_detail()
{
  typeset msg
  typeset tab_level=0
  typeset newline="${YES}"
  typeset newline_cnt=1
  typeset addendum="${NO}"
  typeset stderr="${NO}"
  typeset clear_line="${NO}"
  typeset empty_line="                                                                                "
  
  typeset prefix
  typeset varval="$( __extract_value 'DETAIL_PREFIX' )"
  
  [ -n "${varval}" ] && eval "prefix='${varval}' " || eval "prefix=\"\$( __extract_value 'DEFAULT_DETAIL_PREFIX' )\" "

  typeset remove_prefix="${NO}"

  OPTIND=1
  while getoptex "no-newline m: msg: message: t: tab-level: newline-count: append p: prefix: no-prefix clear-line" "$@"
  do
    case "${OPTOPT}" in
    'm'|'msg'|'message'  ) msg="${OPTARG}";;
    't'|'tab-level'      ) tab_level="${OPTARG}";
                           [ -z "$( __extract_value 'DISPLAY_TAB_MARKER' )" ] && varval=$'\t'
                           ;;
        'no-newline'     ) newline="${NO}";;
        'newline-count'  ) newline_cnt="${OPTARG}";;
        'append'         ) addendum="${YES}"; clear_line="${NO}";;
    'p'|'prefix'         ) prefix="${OPTARG} ";;
        'no-prefix'      ) remove_prefix="${YES}";;
        'clear-line'     ) clear_line="${YES}"; addendum="${NO}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${msg}" ] && return "${PASS}"
  [ "${tab_level}" -lt 0 ] && tab_level=0
  [ "${remove_prefix}" -eq "${YES}" ] && prefix=

  tab_level="$( __make_tab_level --level "${tab_level}" )"

  if [ "${newline}" -ne "${NO}" ]
  then
    newline="\\n"
  else
    newline=
  fi

  if [ -n "${newline}" ]
  then
    typeset cnt=1
    while [ "${cnt}" -lt "${newline_cnt}" ]
    do
      newline+="\\n"
      cnt=$(( cnt + 1 ))
    done
  fi
    
  [ "${clear_line}" -eq "${YES}" ] && printf "%s\r" "${empty_line}"
  if [ -n "${varval}" ]
  then
    if [ "${addendum}" -eq "${NO}" ]
    then
      printf "%s${newline}" "${prefix}${tab_level}${msg}" | \sed -e "s#${varval}#    #g"
    else
      printf "%s${newline}" "${msg}" | \sed -e "s#${varval}#    #g"
    fi
  else
    printf "%s${newline}" "${prefix}${tab_level}${msg}"
  fi
  return "${PASS}"
}

print_program_version()
{
  [ $# -lt 3 ] && return "${FAIL}"
    
  typeset prgstr="$1  -- Version $2  -- Build Date $3"
  typeset prgdiv="$( get_repeated_char_sequence --repeat-char '=' --count ${#prgstr} )"
    
  printf "\n"
  print_btf_detail --msg "${prgdiv}" --no-prefix
  print_btf_detail --msg "$1  -- Version $2  -- Build Date $3" --no-prefix
  print_btf_detail --msg "${prgdiv}" --no-prefix --newline-count 2
  return "${PASS}"
}

process_data()
{
  typeset filename=
  typeset USE_MEMORY="${NO}"
  typeset prefix="${__PROGRAM_VARIABLE_PREFIX}"

  OPTIND=1
  while getoptex "f: filename: use-memory. prefix:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'   ) filename="${OPTARG}";;
        'use-memory' ) USE_MEMORY="${OPTARG}"; [ -z "${USE_MEMORY}" ] && USE_MEMORY="${NO}";;
        'prefix'     ) prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${filename}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  [ -z "${TMP}" ] && TMP="$( \pwd -L )"
  typeset tmpfile="${TMP}/$( \basename "${filename}" )_$( __extract_value 'START_TIME' ).tmp"
  \awk -F'#' '{if ( length($1) > 0 ) print $1}' "${filename}" > "${tmpfile}"
  
  typeset options_in_memory=
  typeset addon_size=8
  typeset prefix_length=$(( ${#prefix} + addon_size )) 
  
  typeset line=
  while read -r -u 9 line
  do
    [ -z "${line}" ] || [ ${#line} -lt 1 ] && continue

    ###
    ### Handle include capabilities...
    ###
    if [ ${#line} -gt "${addon_size}" ] && [ $( printf "%s\n" "${line}" | \cut -c1-${addon_size} ) == '@include' ]
    then
      typeset include_path="$( __evaluate_variable "$( printf "%s\n" "${line}" | \cut -f 2 -d ' ' )" )"
      [ -f "${include_path}" ] && options_in_memory+=$( process_data --filename "${include_path}" --use-memory "${USE_MEMORY}" --prefix "${prefix}" )
      continue
    fi
    
    ###
    ### Process each line to see what should be done...
    ###
    line=$( printf "%s\n" "${line}" | \sed -e 's#\s+=\s+#=#' )

    typeset key=$( printf "%s\n" "${line}" | \cut -f 1 -d '=' )
    
    ###
    ### Check to see if the prefix is already present, if so DON'T change anything; else at the program prefix
    ###
    if [ "x$( printf "%s\n" "${key}" | \cut -c1-${#prefix} )" == "x${prefix}" ]
    then
      key="${key}"
    else
      key="$( __define_internal_variable "${key}" "${prefix}" )"
    fi
    
    ###
    ### Handle the value interpolation using what is done to the internal file first, before going to external means...
    ### TODO: Need to move this into a separate routine for easier usage...
    ###
    typeset value="$( printf "%s\n" "${line}" | \cut -f 2- -d '=' )"

    value=$( __internal_substitute "${value}" )  ### Allows for re-use of internal defined variables
    value=$( __substitute "${value}" )           ### Allows for pre-defined variables
    [ "${key:0:${prefix_length}}" == "${prefix}_PREFIX_" ] && value="[$( printf "%-11s\n" "${value}" | \sed -e 's#\[\(.*\)\]#\1#g' )]"

    options_in_memory+=$( __import_variable  --use-memory "${USE_MEMORY}" --key "${key}" --value "'${value}'" )
  done 9< "${tmpfile}"

  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
  [ -n "${options_in_memory}" ] && printf "%s\n" "${options_in_memory}"
  return "${PASS}"
}

record_step()
{
  [ -z "${RECORD_STEPS}" ] || [ "${RECORD_STEPS}" -ne "${YES}" ] && return "${PASS}"

  typeset begin_time=
  typeset overhead_style='DYNAMIC'

  if [ -n "${RECORD_OVERHEAD}" ] && [ "${RECORD_OVERHEAD}" -eq "${YES}" ]
  then
    begin_time="$( __extract_value 'TIMESTAMP' )"
    [ -z "${begin_time}" ] && begin_time="$( __extract_value 'STARTUP_TIME' )"
  fi
  
  typeset channel
  typeset header
  typeset start_or_stop
  typeset message=
  typeset use_old_style="${NO}"
  
  type "__has_installed" 2>/dev/null | \grep -q 'is a function'
  if [ $? -eq "${PASS}" ]
  then
    [ $( __has_installed base_logging ) -eq "${NO}" ] && . "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  else
    use_old_style="${YES}"
  fi

  OPTIND=1
  while getoptex "c: channel: h: header: start stop m: msg: message: o: overhead-type:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'channel'         ) channel="${OPTARG}";;
    'h'|'header'          ) header="${OPTARG}";;
    'm'|'msg'|'message'   ) message="${OPTARG}";;
    'o'|'overhead-type'   ) overhead_style="${OPTARG}";;
        'start'           ) start_or_stop="$( __extract_value 'RECORDER_STARTING' )";;
        'stop'            ) start_or_stop="$( __extract_value 'RECORDER_STOPPING' )";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -n "${begin_time}" ] && __update_overhead "${overhead_style}" "${begin_time}" "$( __today_as_seconds )"

  [ -z "${channel}" ] && return "${FAIL}"
  [ -z "${header}" ] && header='UNKNOWN'
  
  typeset expected_output="${start_or_stop} [ ${header} ] ${message}"
  expected_output=$( trim "${expected_output}" )
  
  if [ "${use_old_style}" -eq "${YES}" ]
  then
    printf "%s\n" "$( gather_timestamp ) -- ${expected_output}"
  else
    append_output --data "$( gather_timestamp ) -- ${expected_output}" --channel "${channel}" --raw
  fi
  return "${PASS}"
}

request_lock_with_timer()
{
  __debug $@
  
  typeset lockfile="$1"
  typeset differential_time="$2"
  
  typeset count=0
  while [ "${count}" -lt "${differential_time}" ]
  do
    if [ -f "${lockfile}" ]
    then
      sleep 1
      count=$(( count + 1 ))
    else
      \touch "${lockfile}"
      return "${PASS}"
    fi
  done
  
  return "${FAIL}"
}

setup()
{
  typeset program_start_time=$( __today_as_seconds )
  OPTALLOW_ALL="${YES}"

  typeset _PROGRAM_NAME=$( \basename "$0" | \sed 's/\.[^.]*$//' )
  typeset _PROGRAM_NAME_CAP=$( printf "%s\n" "${_PROGRAM_NAME}" | \tr [:lower:] [:upper:] )
  typeset _PROGRAM_STARTUP_DIR="${_PROGRAM_NAME_CAP}_STARTUP_DIR"
  typeset _PROGRAM_LAUNCH_DIR="${_PROGRAM_NAME_CAP}_LAUNCH_DIR"

  ###
  ### Determine locations of all necessary paths especially from where we are starting
  ###
  if [ $( __check_for --key 'HARNESS_ACTIVE' --prefix 'CANOPUS' --failure ) -eq "${YES}" ]
  then
    eval "${_PROGRAM_STARTUP_DIR}=\"$( printf "%s\n" "$0" | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | \cut -d / -f 2- | \sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' )\""
    eval "${_PROGRAM_LAUNCH_DIR}=\"$( \pwd -L )\""

    eval "cd \"\${${_PROGRAM_STARTUP_DIR}}\" > /dev/null"
    eval "${_PROGRAM_STARTUP_DIR}=\"$( \pwd -L )\""
    eval "cd \"\${${_PROGRAM_LAUNCH_DIR}}\" > /dev/null"
    eval "${_PROGRAM_NAME_CAP}_STAND_ALONE=${YES}"
  else
    eval "${_PROGRAM_STARTUP_DIR}=\"$( \pwd -L )\""
    eval "${_PROGRAM_LAUNCH_DIR}=\"{_PROGRAM_STARTUP_DIR}\""
  fi

  eval "__${_PROGRAM_NAME_CAP}_TOPLEVEL=\"\${${_PROGRAM_STARTUP_DIR}}\""

  ###
  ### Finally make the generic replacement
  ###
  eval "_PROGRAM_STARTUP_DIR=\"\${${_PROGRAM_STARTUP_DIR}}\""
  __toplevel="${_PROGRAM_STARTUP_DIR}"
  __PROGRAM_VARIABLE_PREFIX="${_PROGRAM_NAME_CAP}"   #### This is where we set the prefix for the __extract_value calls...

  __setup_paths "${SLCF_SHELL_TOP}" "${program_start_time}" '' "${__toplevel}"
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    printf "\n"
    print_btf_detail --msg "Unable to find support files for $0.  Exiting!" --prefix '[ERROR    ]' --newline-count 2
    return "${RC}"
  fi

  ###
  ### System-wide, harness independent settings
  ###
  typeset optfile="$( __extract_value 'OPTION_FILE' )"

  __import_variable --key 'LC_ALL' --value 'C' --file "${optfile}"
  __import_variable --key '__PROGRAM_OPTION_FILE' --value "${optfile}" --file "${optfile}"
  __import_variable --key '__PROGRAM_VARIABLE_PREFIX' --value "${__PROGRAM_VARIABLE_PREFIX}" --file "${optfile}"

  ###
  ### Define some basic properties
  ###
  __import_variable --key "$( __define_internal_variable 'STARTUP_DIR' )" --value "$( __extract_value 'STARTUP_DIR' )" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'LOGFILE' )" --value "${__toplevel}/.error_warn_${program_start_time}.log" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'SETUP_OPTIONS_FILE' )" --value "$( __extract_value 'STARTUP_DIR' )/.user_options_${program_start_time}" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'DRYRUN' )" --value "${NO}" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable 'INPUT_ARGS' )" --value "$( printf "%s " $@ )" --file "${optfile}"
  __import_variable --key "$( __define_internal_variable '__toplevel' )" --value "${_PROGRAM_STARTUP_DIR}" --file "${optfile}"

  ###
  ### Reorder command line options as necessary to support getoptex
  ###
  typeset cleaned_options=$( cleanup_options "${__toplevel}/.error_warn_${program_start_time}.log" $@ )
  
  ###
  ### Gain access to all help screens for the Canopus Test Harness system
  ###
  [ -f "${__toplevel}/help/.load_all_${_PROGRAM_NAME}_usage_screens.sh" ] && . "${__toplevel}/help/.load_all_${_PROGRAM_NAME}_usage_screens.sh"
  
  ###
  ### Read in system specific file data to import into environment
  ###
  __set_internal_value 'SYSTEM_DATA_FILE' "${__toplevel}/data/${_PROGRAM_NAME}/.std_${_PROGRAM_NAME}_data"
  __set_internal_value 'SETTINGS' "$( __handle_option_management ${cleaned_options} )"

  ###
  ### Separate options to be eval'd into memory (from string/file) and those which should be passed along
  ###
  typeset errmsg=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 4 -d '@' )
  typeset show_usage=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 3 -d '@' | \cut -f 1 -d '|' )
  typeset help_screens=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 3 -d '@' | \cut -f 2 -d '|' | \sed -e 's#^[[:blank:]]##' )
  
  typeset option_preparation=$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 1 -d '@' )
  [ -n "${option_preparation}" ] && eval "${option_preparation}"

  __set_internal_value 'SETTINGS' "$( printf "%s\n" "$( __extract_value 'SETTINGS' )" | \cut -f 2 -d '@' | \tr '|' ' ' )"

  ###
  ### Source the options file while in this function (we are in a subshell)
  ###
  [ -f "${optfile}" ] && . "${optfile}"
  if [ $( __check_for --key 'VERBOSE' --success ) -eq "${YES}" ]
  then
    if [ -n "${optfile}" ] && [ -f "${optfile}" ]
    then
      printf "\n%s\n\n%s\n" "RUNTIME OPTIONS FILE" "$( __extract_value 'DIVIDER' )" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
      \cat "${optfile}" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
      printf "%s\n\n" "$( __extract_value 'DIVIDER' )" >> "$( __extract_value 'STARTUP_DIR' )/.error_warn_${program_start_time}.log"
    fi
  fi

  [ -z "${show_usage}" ] && show_usage=0

  ###
  ### Check to see if the help screen should be shown and exit
  ###
  if [ "${show_usage}" -ne 0 ]
  then
    if [ "${show_usage}" -eq 1 ] || [ "${show_usage}" -eq "${HELP}" ]
    then
      [ -n "${errmsg}" ] && printf "\n%s\n" "${errmsg}" 1>&2
      usage ${help_screens}
      return "${show_usage}"
    fi
  fi

  printf "%s@%s\n" "${optfile}" "$( __extract_value 'SETTINGS' )"
  return 0
}

store_generated_output()
{
  typeset outputdir=
  
  OPTIND=1
  while getoptex "output-dir:" "$@"
  do
    case "${OPTOPT}" in
    'output-dir')    outputdir="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Determine if a premature exit was instantiated
  ###
  typeset premature_exit="$( __extract_value 'PREMATURE_EXIT' )"
  typeset newline_mrk="$( __extract_value 'DISPLAY_NEWLINE_MARKER' )"
  typeset tab_mrk="$( __extract_value 'DISPLAY_TAB_MARKER' )"

  if [ -n "${premature_exit}" ] && [ "${premature_exit}" -eq "${YES}" ]
  then
    outputdir="$( __extract_value 'STARTUP_DIR' )/PREMATURE_EXIT/$( __extract_value 'START_TIME' )"
    typeset premature_msg="$( __extract_value 'PREMATURE_EXIT_MSG' )"
    premature_msg+="${newline_mrk}Any generated files will be found in directory << ${outputdir} >>${newline_mrk}"
    
    printf "$( __extract_value 'PREFIX_ERROR' ) %s\n" "${premature_msg}" | \sed -e "s#${newline_mrk}#$( printf "\n" )#g" -e "s#${tab_mrk}#   #g" 1>&2
    \mkdir -p "${outputdir}"
    if [ $? -ne "${PASS}" ]
    then
      printf "%s\n" "Unable to make collection directory.  Might this disk be full or have improper permissions???"
      return "${PASS}"
    fi
  fi
  
  type "__has_installed" 2>/dev/null | \grep -q 'is a function'
  if [ $? -eq "${PASS}" ]
  then
    [ $( __has_installed base_logging ) -eq "${NO}" ] && return "${PASS}"
  fi

  typeset all_known_channels=$( get_all_output_channels )
  typeset ch=
  for ch in ${all_known_channels}
  do
    mark_channel_persistent --channel "${ch}" --remove
  done

  ###
  ### "Garbage" collect external resource files and place into the appropriate
  ###   output results directory
  ###
  if [ -n "${outputdir}" ] && [ -d "${outputdir}" ]
  then
    ###
    ### Need to extract this so that it is NOT a requirement
    ###
    typeset tpdir="$( __extract_value 'RESULTS_DIR' )"
    if [ -z "${tpdir}" ] || [ ! -d "${tpdir}" ]
    then
      for ch in ${all_known_channels}
      do
        remove_output_file --channel "${ch}"
      done
      all_known_channels=$( get_all_output_channels )
    fi

    ###
    ### Get all channels opened and move them to the appropriate output results directory
    ###
    for ch in ${all_known_channels}
    do
      typeset outfilename=$( find_output_file --channel "${ch}" )
      if [ -n "${outfilename}" ] && [ -f "${outfilename}" ]
      then
        ###
        ### Allow for <SKIP> setting to NOT move file!!!
        ###
        typeset match="$( \grep "${outfilename}" "${tpdir}/.cleanup" | \head -n 1 )"
        if [ -n "${match}" ]
        then
          typeset subdir=$( get_element --data "${match}" --id 2 --separator ':' )
          [ "${subdir}" != '<SKIP>' ] && __register_cleanup "${outfilename}" 'outputs'
        fi
      else
        __register_cleanup "${outfilename}" 'outputs'
      fi
    done
        
    typeset fn=
    for fn in $@
    do
      [ -n "${fn}" ] && [ -f "${fn}" ] && __register_cleanup "${fn}" 'other'
    done

    if [ -f "${tpdir}/.cleanup" ]
    then
      typeset fd=
      for fd in $( \cat "${tpdir}/.cleanup" )
      do
        typeset file_or_dir=$( get_element --data "${fd}" --id 1 --separator ':' )
        typeset subdir=$( get_element --data "${fd}" --id 2 --separator ':' )
      
        typeset collection_dir="${outputdir}/${subdir}"
        [ ! -d "${collection_dir}" ] && \mkdir -p "${collection_dir}"
        if [ -n "${file_or_dir}" ] && [ -e "${file_or_dir}" ]
        then
          #if [ "${premature_exit}" -eq "${YES}" ]
          #then
          #  typeset cp_opts=' -f'
          #  if [ -d "${file_or_dir}" ]
          #  then
          #    cp_opts=' -dpr'
          #  fi
          #  \cp ${cp_opts} "${file_or_dir}" "${collection_dir}/$( \basename "${file_or_dir}" )"
          #else
            \mv -f "${file_or_dir}" "${collection_dir}/$( \basename "${file_or_dir}" )"
          #fi
        fi
      done
    
      [ ! -d "${outputdir}/inputs" ] && \mkdir -p "${outputdir}/inputs"
      if [ $( __check_for --key 'PREMATURE_EXIT' --success ) -eq "${YES}" ]
      then
        \cp -f "${tpdir}/.cleanup" "${outputdir}/inputs"
      else
        \mv -f "${tpdir}/.cleanup" "${outputdir}/inputs"
      fi
    fi
  fi
  return "${PASS}"
}

validate_basic_binaries()
{
  typeset bp=
  typeset bp_failures=0
  typeset RC="${PASS}"

  typeset maxsize=0
  for bp in $@
  do
    typeset size=${#bp}
    [ "${size}" -ge "${maxsize}" ] && maxsize="${size}"
  done

  typeset divider="$( __extract_value 'DIVIDER' )"
  
  if [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ]
  then
    printf "\n"
    print_btf_detail --msg "${divider}" --no-prefix
  fi
  
  typeset exemsg=
  for bp in $@
  do
    typeset diffsize=$(( maxsize - ${#bp} + 1 ))
    [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && exemsg="Verified existence of << ${bp} >> $( printf "%-${diffsize}s" ' ' ) : "
    \which "${bp}" 2>&1 | \grep -q "no ${bp}"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      bp_failures=$(( bp_failures + 1 ))
      [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && print_btf_detail --msg "${exemsg} [FAIL]" --no-prefix
    else
      [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && print_btf_detail --msg "${exemsg} [PASS]" --no-prefix
    fi
  done

  if [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ]
  then
    printf "\n"
    exemsg="Basic validation of necessary OS programs : "
  fi
  
  if [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ]
  then
    if [ "${bp_failures}" -lt 1 ]
    then
      print_btf_detail --msg "${exemsg} [PASS]" --no-prefix
    else
      print_btf_detail --msg "${exemsg} [FAIL]" --no-prefix
    fi
  fi
  
  [ $( __check_for --key 'QUIET' --failure ) -eq "${YES}" ] && print_btf_detail --msg "${divider}" --no-prefix
  return "${bp_failures}"
}

__initialize_program_utilities
