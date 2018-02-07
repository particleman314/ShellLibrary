#!/usr/bin/env bash

local_machinespecs
if [ "${OSVARIETY}" == 'linux' ]
then
  answer=$( __get_linux_version )
  assert_success $?
  assert_not_empty "${answer}"
  assert_not_equals 'UNKNOWN' "${answer}"
  detail "Linux Machine Version: ${answer}"
fi
