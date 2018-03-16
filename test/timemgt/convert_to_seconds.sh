#!/usr/bin/env bash

detail "OS Type : ${OSVARIETY}"
if [ "${OSVARIETY}" != 'solaris' ]
then
  answer=$( convert_to_seconds "$( \date )" )
  assert_not_empty "${answer}"

  if [ "${OSVARIETY}" != 'darwin' ]
  then
    answer=$( convert_to_seconds 'TZ="America/Los_Angeles" 09:00 next Fri' )
    assert_not_empty "${answer}"
  fi
fi
