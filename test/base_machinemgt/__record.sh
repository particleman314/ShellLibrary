#!/bin/sh

assert_not_empty "${OSVARIETY}"

f1=$( make_output_file --channel 'TEST' )
assert_success $?
assert_not_empty "${f1}"

__record
assert_failure $?

__record --method 'w'
assert_failure $?

__record --data 'Hello World'
assert_success $?

if [ -n "${f1}" ]
then
  __record --method 'w' --file "${f1}"
  assert_failure $?

  begin_fs=$( __calculate_filesize "${f1}" )
  __record --method 'w' --file "${f1}" --data 'First Line Written'
  assert_success $?
  after_fs=$( __calculate_filesize "${f1}" )
  assert_not_equals "${begin_fs}" "${after_fs}"
  assert_comparison --comparison '>' "${after_fs}" "${begin_fs}"

  begin_fs="${after_fs}"
  __record --file "${f1}" --data 'Second Line'
  assert_success $?
  after_fs=$( __calculate_filesize "${f1}" )
  detail "Before : ${begin_fs} -- After : ${after_fs}"
  assert_not_equals "${begin_fs}" "${after_fs}"
  assert_comparison --comparison '>' "${after_fs}" "${begin_fs}"
fi
