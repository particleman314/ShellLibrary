#!/usr/bin/env bash

assert_empty $( trim '' )
assert_equals 'ARGH' $( trim "  ARGH  " )
