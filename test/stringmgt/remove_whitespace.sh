#!/usr/bin/env bash

assert_empty $( remove_whitespace '' )
assert_equals 'ARGH' $( remove_whitespace "  ARGH  " )
