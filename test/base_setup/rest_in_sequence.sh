#!/bin/sh

word_list="A quick brown fox jumped over the lazy dog"

assert_equals 9 $( __get_word_count "${word_list}" )

\which 'seq' >/dev/null 2>&1
if [ $? -eq 0 ]
then
  for i in $( \seq 1 5 )
  do
    word_list=$( rest_in_sequence --data "${word_list}" )
  done

  assert_equals 4 $( __get_word_count "${word_list}" )
else
  detail "Unable to complete testing since 'seq' executable not found"
fi
