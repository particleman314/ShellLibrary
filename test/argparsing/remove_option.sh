#!/bin/sh

current_option="${OPTALLOW_ALL}"
OPTALLOW_ALL="${YES}"

cmdline_args="-a 1 -b 2 -c 444 444 --long-opt '6789 hello' --dblquote \"hello world\""

trial1="${cmdline_args}"
assert_not_empty -- "${trial1}"

detail "cmdline args --> ${cmdline_args}"

answer="$( remove_option 1 'a:1:0' ${trial1} )"
assert_not_empty -- "${answer}"

detail "1) remaining options --> ${answer}"

answer="$( remove_option 1 'c:2:0' ${trial1} )"
assert_not_empty -- "${answer}"

detail "2) remaining options --> ${answer}"

trial1="${cmdline_args}"

answer="$( remove_option 1 'long-opt:1:1' ${trial1} )"
assert_not_empty -- "${answer}"

detail "3) remaining options --> ${answer}"

trial1="${cmdline_args}"

answer="$( remove_option 1 'dblquote:1:1' ${trial1} )"
assert_not_empty -- "${answer}"

detail "4) remaining options --> ${answer}"

OPTALLOW_ALL="${current_option}"