#!/usr/bin/env bash

sample_sa=$( make_temp_dir )
schedule_for_demolition "${sample_sa}"

answer=$( __get_storage_area )
assert_empty "${answer}"

__set_storage_area "${sample_sa}"
answer=$( __get_storage_area )
assert_not_empty "${answer}"
assert_equals "${sample_sa}" "${answer}"
detail "TeamCity Storage Area : ${answer}"
