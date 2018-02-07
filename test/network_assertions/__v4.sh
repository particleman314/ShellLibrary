#!/usr/bin/env bash

octet=0
answer=$( __v4 ${octet} )
assert_true "${answer}"

octet=255
answer=$( __v4 ${octet} )
assert_true "${answer}"

octet=666
answer=$( __v4 ${octet} )
assert_false "${answer}"
