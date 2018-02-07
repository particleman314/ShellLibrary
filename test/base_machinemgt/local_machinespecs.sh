#!/usr/bin/env bash

local_machinespecs
assert_not_empty "${OSBITSIZE}"
assert_not_empty "${OSVARIETY}"

detail "OS variety : ${OSVARIETY}"
detail "OS bitsize : ${OSBITSIZE}"
