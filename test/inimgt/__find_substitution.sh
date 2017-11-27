#!/bin/sh

__find_substitution
assert_failure $?

### single sided substitution finding match
__find_substitution '{'
assert_failure $?

### no input for finding matching enclosure
__find_substitution '[' ']'
assert_failure $?

### no match found
answer="$( __find_substitution '<' '>' 'GGG' )"
assert_failure $?

### match found
answer="$( __find_substitution '|' '|' '|GGG|' )"
assert_success $?
assert_equals 'GGG' "${answer}"

### only partial match therefore no match
answer="$( __find_substitution '{' '}' '{GGG|' )"
assert_failure $?

### verify multiple-length characters can be used for matching
answer="$( __find_substitution '%{' '}%' '%{HHH}%' )"
assert_success $?
asswer_equals 'HHH' "${answer}"
