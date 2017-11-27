#!/bin/sh

sample_str=''

new_str=$( remove_trailing_slash --str "${sample_str}" )
assert_success $?
assert_empty "${new_str}"

new_str=$( remove_trailing_slash )
assert_success $?
assert_empty "${new_str}"

sample_str=' '

new_str=$( remove_trailing_slash --str "${sample_str}" )
assert_success $?
assert_empty "${new_str}"

if [ $( is_windows_machine ) -ne "${YES}" ]
then
  sample_str='/How/Are/You/'

  new_str=$( remove_trailing_slash --str "${sample_str}" )
  assert_success $?
  assert '/How/Are/You' "${new_str}"
else
  sample_str 'C:\How\Are\You\'

  new_str=$( remove_trailing_slash --str "${sample_str}" )
  assert_success $?
  assert 'C:\How\Are\You' "${new_str}"
fi
