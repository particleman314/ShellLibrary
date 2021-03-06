#!/usr/bin/env bash
###############################################################################
# Copyright (c) 2016.  All rights reserved. 
# Mike Klusman IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, Mike Klusman IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# Mike Klusman EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
###############################################################################

###############################################################################
#
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- VMWare Management
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    remove_option
#
###############################################################################

[ -z "${__VMWARE_MAP}" ] && __VMWARE_MAP=

__initialize_vmware()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_rest "${SLCF_SHELL_TOP}/lib/rest.sh"
  __load __initialize_passwordmgt "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
  __load __initialize_stringmgt "${SLCF_SHELL_TOP}/lib/stringmgt.sh"
  __load __initialize_networkmgt "${SLCF_SHELL_TOP}/lib/networkmgt.sh"
  __load __initialize_xmlmgt "${SLCF_SHELL_TOP}/lib/xmlmgt.sh"
  __load __initialize_emailmgt "${SLCF_SHELL_TOP}/lib/emailmgt.sh"
  __load __initialize_machinemgt "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  __load __initialize_logging "${SLCF_SHELL_TOP}/lib/logging.sh"
  __load __initialize_hashmaps "${SLCF_SHELL_TOP}/lib/hashmaps.sh"

  __initialize "__initialize_vmware"
}

__prepared_vmware()
{
  __prepared "__prepared_vmware"
}

__get_vmware_xml_rootpath()
{
  hget --map '__VMWARE_MAP' --key 'xml_rootpath'
  return $?
}

__get_vmware_rest_address()
{
  $( __get_rest_api_address $@ )
  return $?
}

__get_vmware_rest_address_port()
{
  $( __get_rest_api_address_port $@ )
  return $?
}

__set_vmware_xml_rootpath()
{
  typeset rp="$1"

  if [ -z "${rp}" ]
  then
    hdel --map '__VMWARE_MAP' --key 'xml_rootpath'
  else
    hput --map '__VMWARE_MAP' --key 'xml_rootpath' --value "${rp}"
  fi
  return $?
}

__set_vmware_rest_address()
{
  $( __set_rest_api_address $@ )
  return $?
}

__set_vmware_rest_address_port()
{
  $( __set_rest_api_address_port $@ )
  return $?
}

__use_soap()
{
  return "${PASS}"
}

get_available_templates()
{
  return "${PASS}"
}

get_available_machines()
{
  return "${PASS}" 
}

deploy_machine_via_template()
{
  return "${PASS}"
}
