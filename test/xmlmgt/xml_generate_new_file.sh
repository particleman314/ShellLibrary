#!/usr/bin/env bash

. "${SLCF_SHELL_TOP}/lib/file_assertions.sh"
assert_success $?

new_xml_file="$( __extract_value 'TEST_SUBSYSTEM_TEMPDIR' )/output.xml"
\touch "${new_xml_file}"
#schedule_for_demolition "${new_xml_file}"

assert_not_empty "${new_xml_file}"
assert_match 'output.' "${new_xml_file}"
assert_is_file "${new_xml_file}"

xml_generate_new_file
assert_failure $?

xml_generate_new_file --xmlfile "${new_xml_file}"
assert_failure $?

xml_generate_new_file --rootnode-id 'level1'
assert_failure $?

xml_generate_new_file --xmlfile "${new_xml_file}" --rootnode-id 'level1'
assert_success $?
assert_has_filesize "${new_xml_file}"

detail "$( \cat "${new_xml_file}" )"

\rm -f "${new_xml_file}"
\touch "${new_xml_file}"

xml_generate_new_file --xmlfile "${new_xml_file}" --rootnode-id 'level1' --subnode 'node1/machine/A'
assert_success $?
detail "Enhanced XML 1 : $( \cat "${new_xml_file}" )"

xml_generate_new_file --xmlfile "${new_xml_file}" --rootnode-id 'level1' --subnode 'node1/machine/B'
assert_success $?
detail "Enhanced XML 2 : $( \cat "${new_xml_file}" )"

xml_generate_new_file --xmlfile "${new_xml_file}" --rootnode-id 'level2' --preserve
assert_success $?
detail "Enhanced XML 3 : $( \cat "${new_xml_file}" )"
