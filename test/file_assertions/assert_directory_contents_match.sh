#! /bin/sh

std_opts="--suppress ${YES} --dnr"

assert_directory_contents_match ${std_opts}
assert_failure "$( __get_last_result )"

tmpfile="$( make_output_file )"
schedule_for_demolition "${tmpfile}"

dirlist1=$( snap_directory_listing --directory "${SLCF_TEMPDIR}" --style before --output-file "${tmpfile}" )
dir2="$( get_temp_dir )"

assert_directory_contents_match ${std_opts} "${tmpfile}" "${dir2}"
assert_failure "$( __get_last_result )"

__reset_assertion_counters
