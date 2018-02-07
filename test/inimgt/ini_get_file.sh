#!/usr/bin/env bash

original_file="$( ini_get_file )"

ini_unset_file
assert_success $?

answer="$( ini_get_file )"
assert_success $?
assert_empty "${answer}"

ini_set_file --inifile 'output.ini' --ignore-existence

answer="$( ini_get_file )"
assert_success $?
assert_not_empty "${answer}"

detail "Std output file : ${answer}"

if [ -z "${original_file}" ]
then
  ini_unset_file
else
  ini_set_file --inifile "${original_file}"
fi

