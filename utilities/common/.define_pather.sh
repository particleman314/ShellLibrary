#!/bin/sh

if [ -z "${REALPATH}" ]
then
  __REALPATH='realpath'
  which 'realpath' >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    __REALPATH='readlink -e'
  else
    __REALPATH_OPTS='-P'
  fi
fi
