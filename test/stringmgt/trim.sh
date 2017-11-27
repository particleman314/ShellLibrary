#!/bin/sh

assert_empty $( trim '' )
assert_equals 'ARGH' $( trim "  ARGH  " )
