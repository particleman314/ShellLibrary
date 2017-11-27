#!/bin/sh

template='Four score and seven years ago...'

strstr "${template}" 'Four'
assert_success $?

strstr "${template}" 'ago'
assert_success $?

strstr "${template}" 'cs'
assert_failure $?

strstr "${template}" 're and se'
assert_success $?

strstr
assert_failure $?

strstr "${template}"
assert_failure $?
