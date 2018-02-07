#!/usr/bin/env bash

__disable_ini_failure "${NO}"
assert_equals "${NO}" "${__INI_FAILURE_SUPPRESSION}"

__disable_ini_failure "${YES}"
assert_equals "${YES}" "${__INI_FAILURE_SUPPRESSION}"

__enable_ini_failure
assert_equals "${NO}" "${__INI_FAILURE_SUPPRESSION}"

__disable_ini_failure
assert_equals "${YES}" "${__INI_FAILURE_SUPPRESSION}"
