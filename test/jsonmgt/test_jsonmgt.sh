#!/usr/bin/env bash

LIBRARY_FUNCTION_FILE='jsonmgt'

###
### If NOT running from the harness, then we need to enable the "launch sequence"
###   else add in the necessary functions from the library file and "let it ride"
### Need to protect against using functionality which may NOT be present since
###   the harness may not be controlling execution
###
if [ -z "${__PROGRAM_VARIABLE_PREFIX}" ]
then
  . "${SLCF_SHELL_UTILDIR}/common/.run_tests.sh" "${LIBRARY_FUNCTION_FILE}" $@
else
  if [ -z "$( __extract_value 'HARNESS_ACTIVE' )" ]
  then
    . "${SLCF_SHELL_UTILDIR}/common/.run_tests.sh" "${LIBRARY_FUNCTION_FILE}" $@
  else
    . "${SLCF_SHELL_FUNCTIONDIR}/${LIBRARY_FUNCTION_FILE}.sh"
  fi
fi

if [ -n "${SLCF_LIBRARY_ISSUE}" ] && [ "${SLCF_LIBRARY_ISSUE}" -eq "${YES}" ]
then
  print_btf_detail --msg "Failure found in startup of ${LIBRARY_FUNCTION_FILE} library" --prefix "$( __extract_value 'PREFIX_FAILURE' )"
  SLCF_LIBRARY_ISSUE=0
fi

unset 'LIBRARY_FUNCTION_FILE'
