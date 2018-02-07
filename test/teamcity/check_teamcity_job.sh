#!/usr/bin/env bash

check_teamcity_job
assert_failure $?

set_teamcity_address "http://teamcity.dev.fco:8111"
check_teamcity_job
assert_failure $?
