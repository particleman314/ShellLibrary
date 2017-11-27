#!/bin/sh

answer=$( invert )
assert_true "${answer}"

answer=$( invert 0 )
assert_true "${answer}"

answer=$( invert 1 )
assert_false "${answer}"

answer=$( invert 9 )
assert_false "${answer}"
