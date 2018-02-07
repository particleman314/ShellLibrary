#!/usr/bin/env bash

###
### Exercise TeamCity at CA
###

sample_user='nimauto'
sample_pwd='nimbus'
sample_cmd='httpAuth/app/rest/agents'

__set_rest_api_address 'TEAMCITY' 'http://teamcity'
__set_rest_api_address_port 'TEAMCITY' '8111'

answer=$( run_rest_api --user-id "${sample_user}" --passwd "${sample_pwd}" --resttype 'TEAMCITY' --command "${sample_cmd}" )
RC=$?
assert_success "${RC}"
assert_not_empty "${answer}"

detail "${answer}"

