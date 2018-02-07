#!/usr/bin/env bash

display_output()
{
  if [ -n "${SLCF_DETAIL}" ]
  then
    [ -n "$1" ] && detail "$1"
  else
    [ -n "$1" ] && printf "\t\t%s\n" "$1"
  fi
}

display_output "No testing to be done.  This is an assignment assertion"
