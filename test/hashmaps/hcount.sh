#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

assert 2 $( hcount --map "${TRIAL_MAP}" )
