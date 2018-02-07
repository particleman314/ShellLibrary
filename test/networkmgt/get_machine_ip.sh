#!/usr/bin/env bash

answer=$( get_machine_ip )
assert_success $?
assert_not_empty "${answer}"

detail "Determine network IP : ${answer}"
detail " "

adapters=$( get_network_adapter_types )
detail "Found Network Adapters : ${adapters}"
detail " "

for n in ${adapters}
do
  answer=$( get_machine_ip --selection "${n}" )
  assert_success "${RC}"
  [ -z "${answer}" ] && answer='<NONE>'
  detail "Adapter ${n} : IPv4 --> ${answer}"
done
detail " "

#for n in ${adapters}
#do
#  answer=$( get_machine_ip --selection "${n}" --ipv 6 )
#  RC=$?
#  [ -n "${answer}" ] && assert_success "${RC}" || assert_failure "${RC}"
#  [ -z "${answer}" ] && answer='<NONE>'
#  detail "Adapter ${n} : IPv6 --> ${answer}"
#done
#printf "%s\n" ' '

#for n in ${adapters}
#do
#  answer=$( get_machine_ip --selection "${n}" --ipv 6 --scope link )
#  RC=$?
#  [ -n "${answer}" ] && assert_success "${RC}" || assert_failure "${RC}"
#  [ -z "${answer}" ] && answer='<NONE>'
#  detail "Adapter ${n} : IPv6 --> ${answer}"
#done
#printf "%s\n" ' '
