#!/usr/bin/env bash

current_optallow_all="${OPTALLOW_ALL}"
OPTALLOW_ALL="${YES}"

opthandler
assert_failure $?

OPTARG=
OPTOPT=

opthandler 'a:bcd:e.' -a 1
RC=$?
answer_OPTARG="${OPTARG}"
answer_OPTOPT="${OPTOPT}"

detail "RC = ${RC} | OPTARG = ${answer_OPTARG} | OPTOPT = ${answer_OPTOPT}"

assert_equals 'a' "${answer_OPTOPT}"
assert_equals 1 "${answer_OPTARG}"
assert_success "${RC}"

OPTALLOW_ALL="${current_optallow_all}"
