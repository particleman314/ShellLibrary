#!/usr/bin/env bash

sample_addr='http://teamcity.dev.fco'

answer=$( __get_teamcity_rest_address )
assert_empty "${answer}"

__set_teamcity_rest_address "${sample_addr}"
answer=$( __get_teamcity_rest_address )
assert_not_empty "${answer}"
assert_equals "${sample_addr}" "${answer}"
detail "TeamCity Address : ${answer}"
