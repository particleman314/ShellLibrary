#!/usr/bin/env bash

email_teamcity_download
assert_failure $?

email_teamcity_download --coordinates 'A:B:C:D"
assert_success $?

email_teamcity_download --coordinates '.lastFinished:develop/bus_ape:robot:klumi01' --datafile 'teamcity/tc_trial_download.xml'
assert_success $?

email_teamcity_download --coordinates '.lastSuccess:develop/bus_cat:hub:klumi01' --blurb 'This is a test email!'
assert_success $?
