#!/bin/sh

sample_port=8001

answer=$( __get_teamcity_rest_address_port )
assert_empty "${answer}"

__set_teamcity_rest_address_port "${sample_port}"
answer=$( __get_teamcity_rest_address_port )
assert_not_empty "${answer}"
assert_equals "${sample_port}" "${answer}"
detail "TeamCity Address Port : ${answer}"

__set_teamcity_rest_address_port

sample_port=0

__set_teamcity_rest_address_port "${sample_port}"
answer=$( __get_teamcity_rest_address_port )
assert_empty "${answer}"
detail "TeamCity Address Port : ${answer}"

__set_teamcity_rest_address_port

sample_port=87495

__set_teamcity_rest_address_port "${sample_port}"
answer=$( __get_teamcity_rest_address_port )
assert_empty "${answer}"
detail "TeamCity Address Port : ${answer}"

__set_teamcity_rest_address_port

sample_port=abc

__set_teamcity_rest_address_port "${sample_port}"
answer=$( __get_teamcity_rest_address_port )
assert_empty "${answer}"
detail "TeamCity Address Port : ${answer}"
