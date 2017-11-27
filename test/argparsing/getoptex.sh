#!/bin/sh

answer=$( getoptex )
assert_failure $?

answer=$( getoptex 'a:' abs )
RC=$?
answer_OPTARG="${SAVE_OPTARG}"
answer_OPTOPT="${SAVE_OPTOPT}"

detail "OPTARG = ${answer_OPTARG} | OPTOPT = ${answer_OPTOPT} | OPTRET = ${OPTRET} | OPTERR = ${OPTERR}"

assert_failure "${RC}"
assert_empty "${answer_OPTARG}"

assert_equals "${answer_OPTOPT}" '?'
detail "Last result = $( __get_last_result )"
