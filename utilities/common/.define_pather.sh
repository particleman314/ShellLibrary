#!/usr/bin/env bash

realpath_internal()
{
  typeset OURPWD="${PWD}"
  cd "$( \dirname "$1" )"

  typeset LINK="$( \readlink "$( \basename "$1" )" )"
  while [ "${LINK}" ]
  do
    cd "$( \dirname "${LINK}" )"
    LINK="$( \readlink "$( \basename "$1" )" )"
  done

  typeset REALPATH="${PWD}/$( \basename "$1" )"
  cd "${OURPWD}"
  printf "%s\n" "${REALPATH}"
}

if [ -z "${REALPATH}" ]
then
  __REALPATH='realpath'
  which 'realpath' >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    __REALPATH="realpath_internal"
    #__REALPATH='readlink'
  else
    __REALPATH_OPTS='-P'
  fi
fi
