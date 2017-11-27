#!/bin/sh

enable_network_adapter
RC=$?
assert_failure "${RC}"

enable_network_adapter --adapter blah
RC=$?
assert_failure "${RC}"
