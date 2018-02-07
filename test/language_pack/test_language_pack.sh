#!/usr/bin/env bash

LIBRARY_FUNCTION_FILE='language_pack'

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
  fi
fi

unset 'LIBRARY_FUNCTION_FILE'
