#!/usr/bin/env bash

temporary_directory="${SUBSYSTEM_TEMPORARY_DIR}"

send_an_email
assert_failure $?

send_an_email --title 'Sample' --current-user "$( get_user_id )" --email-recipients 'klumi01'
assert_failure $?

\cp 'test_emailmgt.sh' "${temporary_directory}/test_emailmgt.sh.mail"
schedule_for_demolition "${temporary_directory}/test_emailmgt.sh.mail"

send_an_email --title 'Sample' --current-user "$( get_user_id )" --email-recipients 'klumi01' --file-to-send "${temporary_directory}/test_emailmgt.sh.mail"
RC=$?
assert_success "${RC}"
assert_not_empty "${RC}"

#cmd_file_output=$( find_output_file --channel 'CMDS' )
#[ -n "${cmd_file_output}" ] && schedule_for_demolition "${cmd_file_output}"

