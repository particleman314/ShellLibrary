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
## @Software Package : Shell Automated Testing -- TAP Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 0.7
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#  * __no_plan
#  * __print_plan
#  * __reset_plan
#  * __skip_all
#  * __test_plan
#  * diag
#  * tap_analyze
#  * fail
#  * pass
#  * ok
#  * has_plan
#  * tap_validate_expected_num_tests
#  * plan
#  * run
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2039,SC2068,SC2034,SC2154,SC2181,SC2059

if [ -z "${__TAP_VERSION}" ]
then
  __TAP_VERSION='13'
  __TAP_INTERNAL_VERSION='0.45'
  __PLAN_INFO_FILE="${SLCF_TEST_RESULTS_SUBSYSTEM}/$( \date "+%s" )_$( \hostname )_$( \whoami ).plan"
fi

__initialize_tap()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_numerics "${SLCF_SHELL_TOP}/lib/numerics.sh"

  # Data components :
  #    plan set | num tests expected | no plan defined | skipped test IDs
  #    <skipped test IDs>
  #        >> 0 is non-existent test ID used to designate no skipped tests
  #        >> -1 is used for all test IDs to be skipped

  printf "%s\n" "${NO}:-1:0:0" > "${__PLAN_INFO_FILE}"
  __initialize "__initialize_tap"

  printf "%s\n" "TAP version ${__TAP_VERSION}"
  diag "TAP internal version (CA) is ${__TAP_INTERNAL_VERSION}"
  #add_trap_callback 'tap_cleanup' EXIT
}

__match()
{
  typeset actual=
  typeset expect=
  typeset testname='unamed_test'
  typeset negative="${NO}"
  
  OPTIND=1
  while getoptex "a: actual: e: expect: n: testname: negative" "$@"
  do
    case "${OPTOPT}" in
    'a'|'actual'    ) actual="${OPTARG}";;
    'e'|'expect'    ) expect="${OPTARG}";;
    'n'|'testname'  ) testname="${OPTARG}";;
        'negative'  ) negative="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  assert_equals --suppress "${YES}" --dnr "${expect}" "${actual}"
  typeset RC="$( __get_last_result )"
    
  typeset output=
  if [ -z "${TAP_VERBOSE}" ] || [ "${TAP_VERBOSE}" -eq "${NO}" ]
  then
    if [ "${RC}" -ne "${PASS}" ]
    then
      [ "${negative}" -eq "${YES}" ] && output+='not ok' || output+='ok'
    else
      [ "${negative}" -eq "${YES}" ] && output+='ok' || output+='not ok'
    fi
  else
    printf "%s" "${testname} "
    if [ "${RC}" -ne "${PASS}" ]
    then
      [ "${negative}" -eq "${YES}" ] && output+='.. not ok ' || output+='.. ok '
    else
      [ "${negative}" -eq "${YES}" ] && output+='.. ok ' || output+='.. not ok '
    fi
    output+="${test_count:-1} - ${1:-0}"
  fi
  
  if [ -n "$2" ] && [ -n "$3" ]
  then
    printf "%s\n" "${output}" | sed -e "s#$2#$3#"
  else
    printf "%s\n" "${output}"
  fi
  return "${RC}"
}

__no_plan()
{
  if [ "$( has_plan )" -eq "${YES}" ]
  then
    printf "%s\n" "Cannot set the plan more than once!"
    return "${PASS}"
  fi

  printf "%s\n" "${YES}:-1:${YES}:0" > "${__PLAN_INFO_FILE}"
}

__prepared_tap()
{
  __prepared "__prepared_tap"
}

__print_plan()
{
  typeset numtests="${1:-?}"
  typeset directive="$2"

  if [ -n "${directive}" ]
  then
    printf "%s\n" "1..${numtests} # ${directive}"
  else
    printf "%s\n" "1..${numtests}"
  fi
  return "${PASS}"
}

__reset_plan()
{
  printf "%s\n" "${NO}:-1:0:0" > "${__PLAN_INFO_FILE}"
}

__skip_all()
{
  typeset reason="${1:-''}"

  if [ "$( has_plan )" -eq "${YES}" ]
  then
    printf "%s\n" "Cannot set the plan more than once!"
    return "${PASS}"
  fi

  __print_plan 0

  printf "%s\n" "${YES}:-1:${NO}:-1" > "${__PLAN_INFO_FILE}"
}

__test_plan()
{
  typeset tests="${1:-?}"
  shift

  [ "${tests}" == '?' ] && tests=0

  if [ "$( has_plan )" -eq "${YES}" ]
  then
    printf "%s\n" "Cannot set the plan more than once!"
    return "${PASS}"
  fi

  if [ "${tests}" -eq 0 ]
  then
    printf "%s\n" "Must run at least one (1) test!"
    return "${FAIL}"
  fi

  __print_plan "${tests}" "$@"
  printf "%s\n" "${YES}:${tests}:${NO}:0" > "${__PLAN_INFO_FILE}"
}

diag()
{
  typeset msgformat="%s\n"

  OPTIND=1
  while getoptex "m: msgformat:" "$@"
  do
    case "${OPTOPT}" in
    'm'|'msgformat'  ) msgformat="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset element=

  while [ $# -gt 0 ]
  do
    printf "${msgformat}" "# $1"
    shift
  done
}

fail()
{
  typeset name="$1"
  __match "${FAIL}" "${name}"
}

file_report_for_failed_tests()
{
  typeset failure_report=
}

has_plan()
{
  typeset value=$( \head -n 1 "${__PLAN_INFO_FILE}" | \cut -f 1 -d ':' )
  printf "%s\n" "${value}"
  return "${PASS}"
}

not_ok()
{
  if [ $# -lt 2 ]
  then
    __match --expect "${FAIL}" --actual "$1" --negative
  else
    __match --expect "${FAIL}" --actual "$1" --testname "$2" --negative $@
  fi
}

ok()
{
  if [ $# -lt 2 ]
  then
    __match --expect "${PASS}" --actual "$1" --negative
  else
    __match --expect "${PASS}" --actual "$1" --testname "$2" $@
  fi
}

pass()
{
  typeset name="$1"
  ok "${PASS}" "${name}"
}

# Wrapper function for the different types of plans to make
plan()
{
  [ $# -lt 1 ] && exit 255
  if [ "$( is_numeric_data --data "$1" )" -eq "${YES}" ]
  then
    __test_plan $@
    typeset RC=$?
    [ "${RC}" -ne "${PASS}" ] && exit 255
    return "${PASS}"
  else
    if [ -n "$1" ]
    then
      case $1 in
      'no_plan'  ) shift; __no_plan $@; return "${PASS}";;
      'skip_all' ) shift; __skip_all $@; return "${PASS}";;
      esac
    fi
  fi
  exit 255
}

tap_analyze()
{
  typeset final_result='FAIL'

  typeset plan_validate="$( tap_validate_expected_num_tests )"
  typeset RC=$?

  if [ "${total_pass}" -eq "${total_count}" ] && [ "${RC}" -eq "${PASS}" ]
  then
    printf "%s\n" "ok" "All tests successful."
    final_result='PASS'
  else
    [ -n "${plan_validate}" ] && printf "%s\n" "${plan_validate}"
    file_report_for_failed_tests
  fi

  printf "%s\n" "File=${num_files_processed}, Tests=${total_count},  ${time_used}"
  printf "%s\n" "Result: ${final_result}"
}

tap_validate_expected_num_tests()
{
  typeset value=0
  if [ "$( has_plan )" -eq "${YES}" ]
  then
    value=$( \head -n 1 "${__PLAN_INFO_FILE}" | \cut -f 3 -d ';' )
    if [ "${value}" -gt 0 ] && [ "${value}" -lt "${total_count}" ]
    then
      printf "%s\n" "# Looks like you planned ${value} tests but ran ${total_count}."
      return "${FAIL}"
    fi
  fi
  printf "%s" "${value}"
  return "${PASS}"
}

run_file_tap()
{
  typeset filename="$1"
  typeset bci_shell_path="$2"

  shift 2

  typeset sectiontype=$( printf "%s\n" "${filename}" | \sed -e 's#.t$##' | \tr [:lower:] [:upper:] )
  setup_test_suite "${bci_shell_path}" "${sectiontype}"

  register_test "${sectiontype}"
  timer realt usert systemt "${filename}"
  record_timing "${sectiontype}" "${filename}" "${realt}" "${usert}" "${systemt}"
  complete_registration "${sectiontype}"

  [ -z "${DELAY_SUMMARY}" ] || [ "${DELAY_SUMMARY}" -eq 0 ] && tap_analyze "${sectiontype}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SHELL_ROOT_DIR}/shell_functions/numerics.sh"
fi

__initialize_tap
__prepared_tap
