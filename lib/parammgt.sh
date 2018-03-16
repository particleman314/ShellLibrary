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
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Parameter Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.00
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_empty_line
#    base_process_cmd_options
#    base_process_check_cmd_options
#    base_template_cmd_options
#    build_basic_help
#    check_help
#
###############################################################################

# shellcheck disable=SC2016,SC1090,SC2039,SC2086,SC1117,SC2181

__get_empty_line()
{
  printf "%s" " "
  return "${PASS}"
}

__initialize_parammgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink "$( \dirname '$0' )" )

  __load __initialize_base_logging "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  __initialize "__initialize_parammgt"
}

__prepared_parammgt()
{
  __prepared "__prepared_parammgt"
}

base_process_check_cmd_options()
{
  typeset RC="${FAIL}"
}

base_process_cmd_options()
{
  print_plain --message "debug help ? quietoutputfile: version"
  return "${PASS}"
}

base_template_cmd_options()
{
  print_plain --message "setup show template:"
  return "${PASS}"
}

build_basic_help()
{
  typeset basic_menu=
  basic_menu+=$( print_plain --message "$( get_repeated_char_sequence -c 79 )|||" )
  basic_menu+=$( __get_empty_line )'|||'
  basic_menu+=$( print_plain --message "    Basic Parameter options...|||" )
  basic_menu+=$( __get_empty_line )'|||'
  basic_menu+=$( print_plain --message "          --debug              --     Enable debugging data to be written to screen|||" )
  basic_menu+=$( print_plain --message "       -?|--help|--?           --     Show this usage screen|||" )
  basic_menu+=$( print_plain --message "         |--outputfile=<>      --     Define outputfile for recorded content written to screen|||" )
  basic_menu+=$( print_plain --message "         |--quiet              --     Suppress all output to screen|||" )
  basic_menu+=$( print_plain --message "         |--version            --     Show version of tool set|||" )

  printf "%s\n" "${basic_menu}" | \sed -e "s#|||#\\n#g"
  return "${PASS}"
}

check_help()
{
  if [ -z "${PROGRAM_HELP}" ] && [ "${PROGRAM__HELP}" -eq "${YES}" ]
  then
    type "usage" 2>/dev/null | \grep -q 'is a function'
    if [ $? -eq 0 ]
    then
      usage
      exit "${PROGRAM_HELP}"
    fi
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_FUNCTIONDIR}/base_logging.sh"
fi

__initialize_parammgt
__prepared_parammgt
