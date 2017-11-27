#!/bin/sh

answer=$( __supports_ipv )
RC=$?
assert_failure "${RC}"
assert_equals "${NO}" "${answer}"
detail "Answer = ${answer}"

answer=$( __supports_ipv --ipv 4 )
RC=$?
assert_failure "${RC}"
assert_equals "${NO}" "${answer}"
detail "Answer = ${answer}"
