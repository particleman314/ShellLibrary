#!/bin/sh

sample=
answer="$( convert_from_artifactory_coordinate "${sample}" )"
assert_success $?

sample='a/bb/ccc/4.0/ccc-4.0.zip'
answer="$( convert_from_artifactory_coordinate "${sample}" )"
assert_success $?
detail "Answer = ${answer}"
