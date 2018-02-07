#!/usr/bin/env bash

assert_not_empty "${TRIAL_MAP}"

assert_not_match blah $( hget --map "${TRIAL_MAP}" --key keys )
