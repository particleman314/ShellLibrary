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
## @Software Package : Shell Automated Testing -- Assertions
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.44
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_assertion_file
#    __get_last_result
#    __get_latest_assertion_id
#    __handle_force_or_skipped_test
#    __initialize_assertions
#    __pass_or_skip
#    __record_assertion
#    __record_fail
#    __record_pass
#    __record_skip
#    __reset_assertion_file
#    __reset_assertion_counters
#    __setup_assertion_file
#    __setup_maps
#    __space_handler
#    assert
#    assert_abort
#    assert_comparison
#    assert_empty
#    assert_equals
#    assert_fail
#    assert_failure
#    assert_false
#    assert_greater_equal
#    assert_greater
#    assert_less_equal
#    assert_less
#    assert_match
#    assert_not_empty
#    assert_not_equals
#    assert_not_match
#    assert_success
#    assert_true
#
###############################################################################

# shellcheck disable=SC2034,SC2124,SC2016,SC2039,SC2089,SC2090,SC2086,SC1117

__get_assertion_file()
{
  [ -n "${__assertion_file}" ] && printf "%s\n" "${__assertion_file}"
  return "${PASS}"
}

__get_last_result()
{
  printf "%d\n" "${__last_result}"
  return "${PASS}"
}

__get_latest_assertion_id()
{
  printf "%d\n" "${__tracked_assertion_id}"
  return "${PASS}"
}

__handle_force_or_skipped_test()
{
  typeset input_args="$1"
  typeset result="${PASS}"
  
  if [ -n "${FORCED_SKIP_TEST}" ] && [ "${FORCED_SKIP_TEST}" -ge 1 ]
  then
    input_args+=" --title \"$( __space_handler 'Force Skip' )\""
    input_args+=" --cause \"$( __space_handler "${__force_skip_msg}" )\""
    __record_skip ${input_args}
    result="${__FORCE_FAIL_SKIP}"
  fi

  input_args+=" $2"
  if [ -n "${FORCED_FAIL_TEST}" ] && [ "${FORCED_FAIL_TEST}" -ge 1 ]
  then
    input_args+=" --title \"$( __space_handler 'Force Fail' )\""
    input_args+=" --cause \"$( __space_handler "${__force_fail_msg}" )\""
    __record_fail ${input_args}
    result="${__FORCE_FAIL_SKIP}"
  fi

  return "${result}"
}

__initialize_assertions()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
  
  # shellcheck source=/dev/null

  . "${SLCF_SHELL_TOP}/lib/constants.sh"

  __space_key='__SS__'
  __assertion_file=

  __map_key_func_pass=
  __map_key_func_fail=
  __map_key_func_skip=
  
  __last_result="${PASS}"
  __unknown_subsystem_id=0
  __unknown_assertion_id=0
  __tracked_assertion_id=0
    
  __SKIP=2
  __force_skip_msg='Test requested to be forcibly skipped!'
  __force_fail_msg='Test requested to be forcibly failed!'
  
  __FORCE_FAIL_SKIP=129
  __INITIALIZE_ASSERTIONS="${YES}"
}

__pass_or_skip()
{
  if [ "$( __get_last_result )" -eq "${PASS}" ] || [ "$( __get_last_result )" -eq "${__FORCE_FAIL_SKIP}" ]
  then
    return "${PASS}"
  else
    return "$( __get_last_result )"
  fi
}

__record_assertion()
{
  typeset expected=
  typeset actual=
  typeset cause=
  
  typeset title=
  typeset testname=
  typeset filename=
  typeset assert_id=
  typeset test_id=
  typeset assert_type='SKIP'
  typeset dnr="${NO}"
  typeset skip_filename="${NO}"

  typeset suppression="${NO}"
  
  OPTIND=1
  while getoptex "a: actual: e: expect: c: cause: ast: aid: tid: t: testname: title: dnr f: filename: s: suppress: disable-filename" "$@"
  do
    case "${OPTOPT}" in
    'a'|'actual'             ) actual="$( __space_handler "${OPTARG}" 1 )";;
    'e'|'expect'             ) expected="$( __space_handler "${OPTARG}" 1 )";;
    'c'|'cause'              ) cause="$( __space_handler "${OPTARG}" 1 )";;
        'title'              ) title="$( __space_handler "${OPTARG}" 1 )";;
        'ast'                ) assert_type="${OPTARG}";;
        'aid'                ) assert_id="${OPTARG}";;
        'tid'                ) test_id="${OPTARG}";;
    't'|'testname'           ) testname="$( __space_handler "${OPTARG}" 1 )";;
    'f'|'filename'           ) filename="${OPTARG}";;
        'disable-filename'   ) skip_filename="${YES}";;
    's'|'suppress'           ) suppression="${OPTARG}";;
        'dnr'                ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${filename}" ] && filename="$( __get_assertion_file )"
  [ "${skip_filename}" -eq "${YES}" ] && filename=
  
  typeset inputs=
  [ -n "${expected}" ] && inputs="<E:${expected}>"
  [ -n "${actual}" ] && inputs+="<A:${actual}>"
  inputs=$( printf "%s\n" "${inputs}" | \sed -e 's#^ ##' -e 's# $##' )  ### This is a trim function...

  __tracked_assertion_id=$(( __tracked_assertion_id + 1 ))
  
  if [ "${dnr}" -ne "${YES}" ]
  then
    if [ -z "${assert_id}" ]
    then
      if [ -z "${__ASSERTION_ID_DEFINED}" ]
      then
        __unknown_assertion_id=$(( __unknown_assertion_id + 1 ))
        assert_id="${__unknown_assertion_id}"
      else
        assert_id="${__ASSERTION_ID_DEFINED}"
      fi
    fi
 
    if [ -z "${test_id}" ]
    then
      if [ -z "${__TEST_ID_DEFINED}" ]
      then
        test_id=-1
      else
        test_id="${__TEST_ID_DEFINED}"
      fi
    fi
    
    if [ -z "${testname}" ]
    then
      if [ -z "${__TESTNAME_ID_DEFINED}" ]
      then
        testname="UNKNOWN_A_${assert_id}"
      else
        testname="${__TESTNAME_ID_DEFINED}"
      fi
    fi
  fi

  typeset assertion_response=
  case "${assert_type}" in
  'PASS' ) assertion_response='PASSED'; __last_result="${PASS}"; [ -z "${title}" ] && title='Assertion Test passed';;
  'FAIL' ) assertion_response='FAILED'; __last_result="${FAIL}"; [ -z "${title}" ] && title='Assertion Test failed';;
  *      ) assertion_response='SKIPPED'; __last_result="${__SKIP}"; [ -z "${title}" ] && title='Assertion Test skipped';;
  esac

  if [ "${dnr}" -ne "${YES}" ]
  then
    typeset common_str="(TID:${test_id}|AID:${assert_id}) Test ${assertion_response} : ${title} : ${testname}"
    if [ -n "${expected}" ]
    then
      common_str+=" : Expectation = <${expected}>"
      [ -n "${actual}" ] && common_str+=", Actual = <${actual}>"
    else
      [ -n "${actual}" ] && common_str+=" : Actual = <${actual}>"
    fi
  
    [ -n "${cause}" ] && [ "${assert_type}" != 'PASS' ] && common_str+=" : Cause --> ${cause}"
    
    if [ -n "${filename}" ]
    then
      printf "%s\n" "${common_str}" >> "${filename}"
    else
      printf "%s\n" "${common_str}"
    fi
  fi

  return "${PASS}"
}

__record_fail()
{
  typeset input_args="--ast FAIL $@"
  __record_assertion ${input_args}
  return $?
}

__record_pass()
{
  typeset input_args="--ast PASS $@"
  __record_assertion ${input_args}
  return $?
}

__record_skip()
{
  typeset input_args="--ast SKIP $@"
  __record_assertion ${input_args}
  return $?
}

__reset_assertion_file()
{
  __setup_assertion_file "$@"
  return "${PASS}"
}

__reset_assertion_counters()
{
  __unknown_subsystem_id=0
  __unknown_assertion_id=0
  __tracked_assertion_id=0
}

__setup_assertion_file()
{
  __assertion_file="$1"
  return "${PASS}"
}

__setup_maps()
{
  typeset map=
  typeset keyfuncs=
  
  OPTIND=1
  while getoptex "m: map: key-func-targ:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'map'           ) map="${OPTARG}";;
        'key-func-targ' ) keyfuncs+=" ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${map}" ] && return "${FAIL}"
  [ -z "${keyfuncs}" ] && return "${PASS}"
  
  typeset kf
  for kf in ${keyfuncs}
  do
    typeset key=$( printf "%s\n" "${kf}" | \cut -f 1 -d ':' )
    typeset funcname=$( printf "%s\n" "${kf}" | \cut -f 2 -d ':' )
    typeset target=$( printf "%s\n" "${kf}" | \cut -f 3 -d ':' | \tr "[:lower:]" "[:upper:]" )
    
    [ -z "${key}" ] || [ -z "${funcname}" ] || [ -z "${target}" ] && continue
    
    case "${target}" in
    'PASS' ) __map_key_func_pass+="${funcname}:${map}:${key}";;
    'FAIL' ) __map_key_func_fail+="${funcname}:${map}:${key}";;
    'SKIP' ) __map_key_func_skip+="${funcname}:${map}:${key}";;
    esac
  done
  return "${PASS}"
}

__space_handler()
{
  [ $# -eq 1 ] && printf "%s\n" "$1" | \sed -e "s# #${__space_key}#g"
  [ $# -eq 2 ] && [ "$2" -eq 1 ] && printf "%s\n" "$1" | \sed -e "s#${__space_key}# #g"
  return "${PASS}"
}

assert()
{
  typeset inputs="$@"
  assert_equals ${inputs}
  return "${PASS}"
}

assert_abort()
{
  typeset expected=
  typeset actual=
  typeset cause=
  
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset errcode="${PASS}"
  
  OPTIND=1
  while getoptex "a: actual: e: expect: c: cause: title: errorcode: error-code: s: suppress: dnr aid: tid: t: testname: f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'actual'                 ) actual="$( __space_handler "${OPTARG}" )";;
    'e'|'expect'                 ) expected="$( __space_handler "${OPTARG}" )";;
    'c'|'cause'                  ) cause="$( __space_handler "${OPTARG}" )";;
        'title'                  ) title="$( __space_handler "${OPTARG}" )";;
        'errorcode'|'error-code' ) errcode="${OPTARG}";;
        'aid'                    ) assert_id="${OPTARG}";;
        'tid'                    ) test_id="${OPTARG}";;
    't'|'testname'               ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename'               ) filename="${OPTARG}";;    
    's'|'suppress'               ) suppression="${OPTARG}";;
        'dnr'                    ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"
  
  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  [ -n "${expected}" ] && speciality_args+=" --expect ${expected}"
  [ -n "${actual}" ] && speciality_args+=" --actual ${actual}"
  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"
  
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Abort" )"
  fi
  
  speciality_args+=" $@"
  assert_fail ${speciality_args}
  exit "${errcode}"
}

assert_comparison()
{
  typeset personal_title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset comparison='='
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  typeset cause=

  typeset current_OAA="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  
  OPTIND=1
  while getoptex "c: comparison: s: suppress: dnr aid: tid: t: testname: f: filename: title: cause:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'comparison' ) comparison="${OPTARG}";;
        'cause'      ) cause="$( __space_handler "${OPTARG}" )";;
        'aid'        ) assert_id="${OPTARG}";;
        'tid'        ) test_id="${OPTARG}";;
        'title'      ) personal_title=" :: ${OPTARG}";;
    't'|'testname'   ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename'   ) filename="${OPTARG}";;    
    's'|'suppress'   ) suppression="${OPTARG}";;
        'dnr'        ) dnr="${YES}";
    esac
  done
  shift $(( OPTIND-1 ))

  OPTALLOW_ALL="${current_OAA}"
  
  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"
  
  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  
  typeset args="$@"
  if [ "${comparison}" == '=' ] || [ "${comparison}" == 'equal' ] || [ "${comparison}" == 'eq' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Equality${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison not equal' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_equals ${speciality_args}
    return "${PASS}"
  fi

  if [ "${comparison}" == '!=' ] || [ "${comparison}" == 'notequal' ] || [ "${comparison}" == 'ne' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Non-Equality${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison equal' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_not_equals ${speciality_args}
    return "${PASS}"
  fi

  if [ "${comparison}" == '<' ] || [ "${comparison}" == 'lessthan' ] || [ "${comparison}" == 'less' ] || [ "${comparison}" == 'lt' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Less Than${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison less than' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_less ${speciality_args}
    return "${PASS}"
  fi

  if [ "${comparison}" == '<=' ] || [ "${comparison}" == 'lessequal' ] || [ "${comparison}" == 'lessthanorequalto' ] || [ "${comparison}" == 'le' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Less|Equal${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison less than or equal' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_less_equal ${speciality_args}
    return "${PASS}"
  fi

  if [ "${comparison}" == '>' ] || [ "${comparison}" == 'greaterthan' ] || [ "${comparison}" == 'greater' ] || [ "${comparison}" == 'gt' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Greater Than${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison greater than' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_greater ${speciality_args}
    return "${PASS}"
  fi

  if [ "${comparison}" == '>=' ] || [ "${comparison}" == 'greaterequal' ] || [ "${comparison}" == 'greaterthanorequalto' ] || [ "${comparison}" == 'ge' ]
  then
    speciality_args+=" --title $( __space_handler "Assert Comparison -- Greater|Equal${personal_title}" )"
    if [ -z "${cause}" ]
    then
      speciality_args+=" --cause $( __space_handler 'Expected versus Actual comparison greater than or equal' )"
    else
      speciality_args+=" --cause ${cause}"
    fi
    speciality_args+=" ${args}"
    assert_greater_equal ${speciality_args}
    return "${PASS}"
  fi

  speciality_args+=" --title $( __space_handler "No Comparion Match${personal_title}" )"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause $( __space_handler 'No match between arguments found' )"
  else
    speciality_args+=" --cause ${cause}"
  fi
  speciality_args+=" ${args}"
  __record_skip ${speciality_args}
  return $?
}

assert_empty()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset cause=
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
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" )";;
    's'|'suppress' ) suppression="${OPTARG}";;
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
    speciality_args+=" --title $( __space_handler "Assert Empty" )"
  fi

  typeset answer="$( __space_handler "$1" )"
  shift
  
  typeset parameter_args=
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"
  if [ -z "${answer}" ]
  then
    speciality_args+=" $@"
    __record_pass ${speciality_args}
    return "${PASS}"
  fi
  
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Non-empty input encountered' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+="$@"
  __record_fail ${speciality_args}
  return $?
}

assert_equals()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset cause=
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
    speciality_args+=" --title $( __space_handler "Assert Equals" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"
  if [ -z "${expectation}" ] || [ -z "${answer}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not enough inputs for comparison' )\""
    __record_fail ${speciality_args}
    return $?
  fi

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Equality not found for inputs' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    if [ "${expectation}" == "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_fail()
{
  typeset testname='Bad Setup'
  typeset expected=' '
  typeset actual=' '
  typeset cause=
  
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
  typeset suppression="${NO}"
  typeset dnr="${NO}"
  
  OPTIND=1
  while getoptex "a: actual: e: expect: c: cause: title: s: suppress: dnr aid: tid: t: testname: f: filename:" "$@"
  do
    case "${OPTOPT}" in
    'a'|'actual'                 ) actual="$( __space_handler "${OPTARG}" )";;
    'e'|'expect'                 ) expected="$( __space_handler "${OPTARG}" )";;
    'c'|'cause'                  ) cause="$( __space_handler "${OPTARG}" )";;
        'title'                  ) title="$( __space_handler "${OPTARG}" )";;
        'aid'                    ) assert_id="${OPTARG}";;
        'tid'                    ) test_id="${OPTARG}";;
    't'|'testname'               ) testname="$( __space_handler "${OPTARG}" )";;
    'f'|'filename'               ) filename="${OPTARG}";;    
    's'|'suppress'               ) suppression="${OPTARG}";;
        'dnr'                    ) dnr="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${cause}" ]
  then
    cause='Bad setup encountered when running test'
    [ -n "${testname}" ] && cause+=" -- ${testname}"
    cause="$( __space_handler "${cause}" )"
  fi
      
  typeset speciality_args="--suppress ${suppression}"
  [ "${dnr}" -eq "${YES}" ] && speciality_args+=" --dnr"
  
  [ -n "${assert_id}" ] && speciality_args+=" --aid ${assert_id}"
  [ -n "${test_id}" ] && speciality_args+=" --tid ${test_id}"
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  [ -n "${expected}" ] && speciality_args+=" --expect ${expected}"
  [ -n "${actual}" ] && speciality_args+=" --actual ${actual}"
  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"
  
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert Failure" )"
  fi
  
  speciality_args+=" $@"
  __record_fail ${speciality_args}
  return $?
}

assert_failure()
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
    'c'|'cause'    ) cause="$( __space_hander "${OPTARG}" )";;
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
    speciality_args+=" --title $( __space_handler "Assert Failure" )"
  fi
  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"

  typeset expectation="$1"
  shift

  expectation="$( printf "%s\n" "${expectation}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )"

  [ -z "${expectation}" ] && expectation="${FAIL}"
  typeset args="${speciality_args} ${expectation} ${PASS}"
  assert_not_equals ${args}
  return $?
}

assert_false()
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
  [ -n "${testname}" ] && speciality_args+=" --testname ${testname}"
  [ -n "${filename}" ] && speciality_args+=" --filename ${filename}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert False" )"
  fi

  typeset expectation="$1"
  shift

  expectation="$( printf "%s\n" "${expectation}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )"

  [ -z "${expectation}" ] && expectation="${NO}"

  typeset args="${speciality_args} ${expectation} ${NO}"
  assert_equals ${args}
  return $?
}

assert_greater_equal()
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
    'c'|'cause'    ) cause="$( __space_handler "${OPTARG}" ) ";;
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
    speciality_args+=" --title $( __space_handler "Assert Greater|Equals" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not greater than or equal to as expected' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    if [ "${expectation}" -ge "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_greater()
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
  while getoptex "title: c: comparison: s: suppress: dnr aid: tid: t: testname: f: filename: c: cause:" "$@"
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
    speciality_args+=" --title $( __space_handler "Assert Greater" )"
  fi

  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not greater than as expected' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    if [ "${expectation}" -gt "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_less_equal()
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
    speciality_args+=" --title $( __space_handler "Assert Less|Equals" )"
  fi

  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
 [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
   
  speciality_args+=" ${parameter_args}"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Not less than or equal to as expected' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    if [ "${expectation}" -le "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_less()
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
    speciality_args+=" --title $( __space_handler "Assert Less" )"
  fi

  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"

  if [ -z "${expectation}" ] || [ -z "${answer}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "Not enough inputs for comparison" )\""
    __record_fail ${speciality_args}
    return $?
  fi

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Equal-to or Greater-than found for inputs' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    if [ "${expectation}" -lt "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_match()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
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
    speciality_args+=" --title $( __space_handler "Assert Match" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
 [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"

  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "Did not find <${expectation}> in output <${answer}>" )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"

  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    printf "%s\n" "${answer}" | \grep -q "${expectation}"
    typeset RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_not_empty()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset cause=
  typeset filename=
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
    speciality_args+=" --title $( __space_handler "Assert Not Empty" )"
  fi
  
  typeset actual="$( __space_handler "$1" )"
  shift

  typeset parameter_args=
  [ -n "${actual}" ] && parameter_args+=" --actual ${actual}"
 
  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Empty input encountered' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"
  if [ -n "${actual}" ]
  then
    __record_pass ${speciality_args}
    return $?
  fi
  
  __record_fail ${speciality_args}
  return $?
}

assert_not_equals()
{
  typeset title=
  typeset assert_id=
  typeset test_id=
  typeset testname=
  typeset filename=
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
    speciality_args+=" --title $( __space_handler "Assert Not Equals" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"

  speciality_args+=" ${parameter_args}"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler 'Equality found for inputs' )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  speciality_args+=" $@"

  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then  
    if [ "${expectation}" != "${answer}" ]
    then
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  __record_fail ${speciality_args}
  return $?
}

assert_not_match()
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
    speciality_args+=" --title $( __space_handler "Assert Not Match" )"
  fi
  
  typeset expectation="$( __space_handler "$1" )"
  typeset answer="$( __space_handler "$2" )"
  shift 2

  typeset parameter_args=
  [ -n "${expectation}" ] && parameter_args+=" --expect ${expectation}"
  [ -n "${answer}" ] && parameter_args+=" --actual ${answer}"

  __handle_force_or_skipped_test "${speciality_args}" "${parameter_args}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${PASS}"
  
  speciality_args+=" ${parameter_args}"
  if [ -z "${cause}" ]
  then
    speciality_args+=" --cause \"$( __space_handler "Found <${expectation}> in output <${answer}>" )\""
  else
    speciality_args+=" --cause ${cause}"
  fi

  if [ -n "${expectation}" ] && [ -n "${answer}" ]
  then
    printf "%s\n" "${answer}" | \grep -q "${expectation}"
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      speciality_args+=" $@"
      __record_pass ${speciality_args}
      return $?
    fi
  fi

  speciality_args+=" --expect 0 --actual ${RC}"
  __record_fail ${speciality_args}
  return $?
}

assert_success()
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
  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"
  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler 'Assert Success' ) "
  fi

  typeset expectation="$1"
  shift

  expectation="$( printf "%s\n" "${expectation}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )"

  [ -z "${expectation}" ] && expectation="${PASS}"

  typeset args="${speciality_args} ${expectation} ${PASS}"
  assert_equals ${args}
  return $?
}

assert_true()
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
  [ -n "${cause}" ] && speciality_args+=" --cause ${cause}"

  if [ -n "${title}" ]
  then
    speciality_args+=" --title ${title}"
  else
    speciality_args+=" --title $( __space_handler "Assert True" )"
  fi

  typeset expectation="$1"
  shift

  expectation="$( printf "%s\n" "${expectation}" | \sed 's#^[ \t]*##;s#[ \t]*$##' )"

  [ -z "${expectation}" ] && expectation="${YES}"

  typeset args="${speciality_args} ${expectation} ${YES}"
  assert_greater_equal ${args}
  return $?
}

# ---------------------------------------------------------------------------
if [ -z "${__INITIALIZE_ASSERTIONS}" ]
then
  __initialize_assertions
else
  if [ "${__INITIALIZE_ASSERTIONS}" -ne 1 ]
  then
    __initialize_assertions
  fi
fi
