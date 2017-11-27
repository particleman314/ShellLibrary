#!/bin/sh

if [ "$( uname -s )" != 'SunOS' ]
then
  answer=$( convert_to_seconds "$( date )" )
  assert_not_empty "${answer}"

  answer=$( convert_to_seconds 'TZ="America/Los_Angeles" 09:00 next Fri' )
  assert_not_empty "${answer}"
fi
