#!/usr/bin/env bash

set_semaphore
assert_failure $?

set_semaphore --directory 'blah'
assert_failure $?

semaphoredir="${SUBSYSTEM_TEMPORARY_DIR}/SEMAPHORE_DIR"
mkdir -p "${semaphoredir}"
schedule_for_demolition "${semaphoredir}"

set_semaphore --directory "${semaphoredir}" --semtype 'abc'
assert_success $?
assert_is_file "${semaphoredir}/abc.sem"

set_semaphore --directory "${semaphoredir}" --semtype 'xyz' --tag 'wow'
assert_success $?
assert_is_file "${semaphoredir}/xyz_wow.sem"
