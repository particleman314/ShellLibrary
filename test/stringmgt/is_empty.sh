#!/usr/bin/env bash

assert_true $( is_empty )
assert_true $( is_empty --str ' ' )
assert_false $( is_empty --str 'ABC' )
assert_true $( is_empty --str '      ' )
assert_false $( is_empty --allow-space --str ' ' )
