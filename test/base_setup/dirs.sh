#! /bin/sh

display_output()
{
  if [ -n "${CANOPUS_DETAIL}" ]
  then
    [ -n "$1" ] && detail "$1"
  else
    [ -n "$1" ] && printf "\t\t%s\n" "$1"
  fi
}

display_output "No testing to be done."
