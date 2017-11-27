#!/bin/sh

assert_not_empty "${OSVARIETY}"

tpdir=$( get_temp_dir )
assert_not_empty "${tpdir}"

tpdir=$( get_temp_dir "${HOME}" )
assert_not_empty "${tpdir}"
assert_match "${HOME}" "${tpdir}"

tpdir=$( get_temp_dir '/BLAH' )
assert_not_empty "${tpdir}"

detail "Temp Directory = ${tpdir}"
