#!/bin/sh

list_name='testl'

internal_list='1 2 5 6 193 8'
hput --map 'internal' --key 'test' --value "${internal_list}"

convert_to_list --object "${list_name}" --hmap 'internal' --hkey 'test'
answer=$( list_size --object "${list_name}" )
assert_equals 6 "${answer}"

list_print --object "${list_name}"
