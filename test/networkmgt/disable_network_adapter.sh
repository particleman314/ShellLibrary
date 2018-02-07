#!/usr/bin/env bash

disable_network_adapter
RC=$?
assert_failure "${RC}"

disable_network_adapter --adapter blah
RC=$?
assert_failure "${RC}"
