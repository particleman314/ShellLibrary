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
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- UIM Assertions
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    assert_configuration_key
#    assert_configuration_section
#
###############################################################################

if [ -z "${SLCF_SHELL_TOP}" ]
then
  SLCF_SHELL_TOP=$( readlink -f "$( dirname '$0' )" )
  SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
  SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
  SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
fi

[ -z "${PASS}" ] && . "${SLCF_SHELL_FUNCTIONDIR}/file_assertions.sh"

assert_configuration_key()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset dnr="${NO}"

  OPTIND=1
  while getoptex "title: s: suppress: dnr aid: tid: t: testname: f: filename:" "$@"
  do
    case "${OPTOPT}" in
        'title'    ) title="$( __space_handler "${OPTARG}" )";;
        'aid'      ) assert_id="${OPTARG}";;
        'tid'      ) test_id="${OPTARG}";;
    't'|'testname' ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename' ) filename="${OPTARG}";;    
    's'|'suppress' ) suppression="${OPTARG}";;
        'dnr'      ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname '${testname}'"
  [ -n "${filename}" ] && speciality_args+=" --filename '${filename}'"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Directory Contents Match" )"
  fi

  typeset configfile="$( __space_handler "$1" )"
  typeset section="$( __space_handler "$2" )"
  typeset key="$( __space_handler "$3" )"
  shift 3

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "$( __get_last_result )"

  if [ ! -f "${expectation}" ] || [ ! -f "${answer}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "File(s) <${expectation}> and/or <${answer}> are not the available" )\""
    __record_fail ${speciality_args} --expect 0 --actual 127
    return "$( __get_last_result )"
  fi

  if [ -z "${configfile}" ] || [ ! -f "${configfile}" ]
  then
    __show_fail ${speciality_args} -t 'Non-Configfile' -e ' ' -a ' ' -c "Unable to find configuration file <${configfile}>"
    return $?
  fi

  typeset testfile="${configfile}"
  if [ -z "${section}" ]
  then
    __show_fail ${speciality_args} -t 'Bad-Section' -e ' ' -a ' ' -c "No section defined for configuration file <${configfile}>"
    return $?
  fi

  if [ -z "${key}" ]
  then
    __show_fail ${speciality_args} -t 'Missing-Key' -e ' ' -a ' ' -c "No key defined for configuration file <${configfile}>"
    return $?
  fi

  typeset components
  components=$( printf "%s" "${section}" | sed -e 's#/# #g' )

  typeset RC
  typeset s
  typeset known_path
  typeset missing_section="${NO}"

  typeset tmpfile=$( make_temp_file )
  register_tmpfile --filename "${tmpfile}" --channel 'SUBSECTION'
 
  for s in ${components}
  do
    typeset begin_line=$( grep -n "<${s}>" "${testfile}" | cut -f 1 -d ':' )
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __show_fail ${speciality_args} -t 'Non-Existent Begin Section Marker' -e "${known_path}/${s}" -a ' ' -c "Unable to find section in configuration file <${configfile}>"
      return $?
    fi

    typeset end_line=$( grep -n "$</${s}>" "${testfile}" | cut -f 1 -d ':' )
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __show_fail ${speciality_args} -t 'Non-Existent End Section Marker' -e "${known_path}/${s}" -a ' ' -c "Unable to find section in configuration file <${configfile}>"
      return $?
    fi

    if [ "${begin_line}" -lt "${end_line}" ]
    then
      typeset next_line=$(( end_line + 1 ))

      sed -n "${begin_line},${end_line}p;${next_line}q" "${testfile}" > "${tmpfile}"
      testfile="${tmpfile}"
      known_path+="/${s}"
    else
      missing_section="${YES}"
      break
    fi
  done

  discard --channel 'SUBSECTION'
 
  if [ "${missing_section}" -eq "${YES}" ]
  then
    __show_fail ${speciality_args} -t 'Missing Section' -e "${section}/${key}" -a "${known_path}" -c "missing section encountered"
  else
    __show_pass ${speciality_args} -t 'assert_configuration_key' -- $@
  fi
  return $?
}

assert_configuration_section()
{
  typeset configfile=
  typeset section=
  typeset suppression="${NO}"
  typeset dnr="${NO}"

  OPTIND=1
  while getoptex "c: configfile: section: s: suppress: dnr" "$@"
  do
    case "${OPTOPT}" in
    'c'|'configfile' ) configfile="${OPTARG}";;
        'section'    ) section="${OPTARG}";;
    's'|'suppress'   ) suppression="${OPTARG:-1}";;
        'dnr'        ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="-s ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"

  if [ -n "${FORCED_FAIL_TEST}" ] && [ "${FORCED_FAIL_TEST}" -ge 1 ]
  then
    __show_fail ${speciality_args} -t 'Non-Configfile' -e '' -a '' -c "test requested to be forcibly failed"
    return $?
  fi

  if [ -n "${FORCED_SKIP_TEST}" ] && [ "${FORCED_SKIP_TEST}" -ge 1 ]
  then
    __show_skip ${speciality_args} "Test requested to be forcibly skipped"
    return $?
  fi

  if [ -z "${configfile}" ] || [ ! -f "${configfile}" ]
  then
    __show_fail ${speciality_args} -t 'Non-Configfile' -e ' ' -a ' ' -c "Unable to find configuration file <${configfile}>"
    return $?
  fi
  
  if [ -z "${section}" ]
  then
    __show_fail ${speciality_args} -t 'Bad-Section' -e ' ' -a ' ' -c "No section defined for configuration file <${configfile}>"
    return $?
  fi
  
  typeset components
  components=$( printf "%s" "${section}" | sed -e 's#/# #g' )
  
  typeset RC
  typeset known_path
  typeset s
  typeset count=0
  
  for s in ${components}
  do
    grep -q "<${s}" "${configfile}"
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      __show_fail ${speciality_args} -t 'Non-Existent Section' -e "${known_path}/${s}" -a ' ' -c "Unable to find section in configuration file <${configfile}>"
      return $?
    fi

    if [ -n "${known_path}" ]
    then
      known_path+="/${s}"
    else
      known_path="${s}"
    fi
    count=$(( count + 1 ))
  done	
  
  if [ "${count}" -eq 0 ]
  then
    __show_fail ${speciality_args} -t 'Non-Empty' -e "${expectation}" -a ' ' -c "Non-empty input encountered"
  else
    __show_pass ${speciality_args} -t "assert_configuration_section" -- $@
  fi
  return $?
}

assert_probe_installation()
{
  TEST_SUB_SYSTEM='installation'
  [ "${TEST_IN_SUITE}" -eq 0 ] && register_test || extend_test

  typeset executable="${TEST_INSTALLATION_PROBE_EXE}"
  typeset min_expect_files="${TEST_INSTALLATION_PROBE_MIN_FILES}"
  typeset min_expect_dirs="${TEST_INSTALLATION_PROBE_MIN_DIRS}"

  # Remove skipped files or directories
  if [ -n "${TEST_SKIP_FILE_CHECK}" ]
  then
    typeset f
    for f in ${TEST_SKIP_FILE_CHECK}
    do
      min_expect_files=$( printf "%s\n" ${min_expect_files} | \grep -v "${f}" | \tr '\n' ' ' )
    done
  fi

  if [ -n "${TEST_SKIP_DIRECTORY_CHECK}" ]
  then
    typeset d
    for d in ${TEST_SKIP_DIRECTORY_CHECK}
    do
      min_expect_dirs=$( printf "%s\n" ${min_expect_dirs} | \grep -v "${d}" | \tr '\n' ' ' )
    done
  fi

  typeset data=$( setup_testing "$( get_tag )" "installation" $(( 1 + $( echo "${executable} ${min_expect_dirs} ${min_expect_files}" | wc -w | sed -e 's#^ *##' | cut -f 1 -d ' ' ) )) )

  typeset nimaddress=$( printf "%s\n" "${data}" | \cut -f 3 -d ':' )

  if [ -z "${nimaddress}" ]
  then
    assert_fail "No nimaddress provided for testing!"
    return
  fi

  typeset cmd=$( printf "%s\n" "${data}" | \cut -f 1 -d ':' )
  typeset outputfile=$( printf "%s\n" "${data}" | \cut -f 2 -d ':' )
  typeset base_outputfn=$( \basename "${outputfile}" )
  typeset probe_location=$( printf "%s\n" "${data}" | \cut -f 5 -d ':' )

  [ -z "${probe_location}" ] && probe_location="${TEST_INSTALLATION_PROBE_RELATIVE_ROOT}"

  typeset ip=$( get_nimaddress_ip "${nimaddress}" )
  [ -z "${ip}" ] && force_fail

  typeset localip=$( get_local_ip )
  typeset probedir="${TEST_NIMROOT}/${probe_location}"

  if [ "${ip}" == "${localip}" ]
  then
    assert_is_directory "${probedir}" "${test_type}"
  else
    typeset output=$( \ssh -q ${TEST_USER_ACCESS}@${ip} "[ -d \"\${probedir}\" ] && printf \"%d\n\" 1 || printf \"%s\n\" 0" 2>&1 )
    assert_equals 1 "${output}"
  fi

  typeset fd
  for fd in ${min_expect_files}
  do
    assert_is_file "${probedir}/${fd}" "${test_type}"
  done

  for fd in ${min_expect_dirs}
  do
    assert_is_directory "${probedir}/${fd}" "${test_type}"
  done

  [ -n "${executable}" ] && assert_is_executable "${probedir}/${executable}" "${test_type}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
