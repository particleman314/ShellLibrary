#!/usr/bin/env bash

detail "Starting test for method : $1"

__determine_packaging_system
assert_success $?
assert_true "${__SETUP_PKG}"

detail "Ending test for method : $1"
