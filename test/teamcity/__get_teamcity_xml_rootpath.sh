#!/bin/sh

sample_xpath='/teamcity/build_server'

answer=$( __get_teamcity_xml_rootpath )
assert_empty "${answer}"

__set_teamcity_xml_rootpath "${sample_xpath}"
answer=$( __get_teamcity_xml_rootpath )
assert_not_empty "${answer}"
assert_equals "${sample_xpath}" "${answer}"
detail "Root XPath : ${answer}"
