#!/usr/bin/env bash

template_word_list="A quick brown fox jumped over the lazy dog"
word_list="${template_word_list}"

answer=$( next_in_sequence --data "${word_list}" )
assert_equals 'A' "${answer}"

sequence="1 2 3"
for i in ${sequence}
do
  word_list=$( rest_in_sequence --data "${word_list}" )
done

answer=$( next_in_sequence --data "${word_list}" )
assert_equals 'fox' "${answer}"

word_list="${template_word_list}"
answer=$( next_in_sequence --data "${word_list}" --id 4 )
assert_equals 'fox' "${answer}"

word_list=$( rest_in_sequence --data "${word_list}" --shift 6 )
answer=$( next_in_sequence --data "${word_list}" )
assert_equals 'the' "${answer}"
