#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

assert_match robot $( hkeys --map "${TRIAL_MAP}" )
