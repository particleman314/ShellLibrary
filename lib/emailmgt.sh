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
## @Software Package : Shell Automated Testing -- Email Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.08
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_company
#    __get_designer
#    __get_maintainer
#    __set_company
#    __set_designer
#    __set_maintainer
#    build_email_list
#    send_an_email
#
###############################################################################

# shellcheck disable=SC2016,SC1117,SC2120,SC2039,SC2068,SC2119,SC2181

if [ -z "${__MAINTAINER}" ]
then
  __MAINTAINER='klusman'
  __DESIGNER='klusman'
  __COMPANY='synopsys.com'
  __EMAIL_OPTS=
  __EMAIL_TMP_DIR=
fi

__generate_sendmail_hookscript()
{
  if [ -n "${SLCF_TEST_TOPLEVEL_TMP}" ] && [ -d "${SLCF_TEST_TOPLEVEL_TMP}" ]
  then
    __EMAIL_TMP_DIR="${SLCF_TEST_TOPLEVEL_TMP}"
  else
    __EMAIL_TMP_DIR="$( get_temp_dir )/$( get_user_id )"
  fi
  
  [ ! -d "${__EMAIL_TMP_DIR}" ] && \mkdir "${__EMAIL_TMP_DIR}"
  
  \cat << EOF > "${__EMAIL_TMP_DIR}/.sendmail-hook"
#!/usr/bin/env bash

\sed '1,/^\$/{
s,^\\(Content-Type: \\).*$,\\1text/html; charset=utf-8,g
s,^\\(Content-Transfer-Encoding: \\).*\$,\\18bit,g
}' | \sendmail \$@
EOF
  __EMAIL_OPTS="-Ssendmail='${__EMAIL_TMP_DIR}/.sendmail-hook'"
}

__get_company()
{
  __debug $@

  printf "%s\n" "${__COMPANY}"
  return "${PASS}"
}

__get_designer()
{
  __debug $@

  printf "%s\n" "${__DESIGNER}"
  return "${PASS}"
}

__get_maintainer()
{
  __debug $@

  printf "%s\n" "${__MAINTAINER}"
  return "${PASS}"
}

__initialize_emailmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} ${__REALPATH_OPTS} "$( \dirname '$0' )" )

  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"

  typeset possible_mail_programs
  typeset found="${NO}"
  
  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    possible_mail_programs='email sendmail'
  else
    possible_mail_programs='sendmail mail'
  fi
  
  typeset mp=
  for mp in ${possible_mail_programs}
  do
    if [ "$( is_empty --str "${mail_exe}" )" -eq "${YES}" ]
    then
      mail_exe="$( get_exe --exename "${mp}" --syscmd )"
      [ -n "${mail_exe}" ] && found="${YES}"
      if [ "${found}" -eq "${YES}" ]
      then
        #printf "%s\n" ${possible_mail_programs} | grep -q '\bmail\b'
        #[ $? -eq 0 ] && __USE_HEADER_SPECIFICATIONS="${NO}"
        __generate_sendmail_hookscript
        break
      fi
    fi
  done
  
  __initialize "__initialize_emailmgt"
  
  if [ "${found}" -eq "${NO}" ]
  then
    return "${FAIL}"
  else
    return "${PASS}"
  fi
}

__prepared_emailmgt()
{
  __prepared "__prepared_emailmgt"
}

__set_company()
{
  __debug $@

  if [ -z "$1" ]
  then
    return "${FAIL}"
  else
    __COMPANY="$1"
  fi
}

__set_designer()
{
  __debug $@

   if [ -z "$1" ]
   then
     return "${FAIL}"
   else
     __DESIGNER="$1"
   fi
}

__set_maintainer()
{
  __debug $@

  if [ -z "$1" ]
  then
    return "${FAIL}"
  else
    __MAINTAINER="$1"
  fi
}

build_email_list()
{
  __debug $@
  
  typeset userid=$( get_user_id )
  typeset email_list=
  typeset company='dev.null'

  OPTIND=1
  while getoptex "e: email: c: company:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'email'   ) email_list+=" ${OPTARG}";;
    'c'|'company' ) company="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  # Handle email address (duplicates are possible)
  typeset base_emails="$( __get_maintainer )"

  [ "${userid}" != "$( __get_maintainer )" ] && [ "${userid}" != "$( __get_designer )" ] && base_emails+=" ${userid}"

  ###
  ### Need to determine if email is FQDN
  ###
  typeset all_email_address=
  typeset mr=
  for mr in ${email_list} ${base_emails}
  do
    mr="$( printf "%s\n" "${mr}" | \tr '.' '_' )"
    #typeset mapkey=$( hget --map email_address --key "${mr}" )
    #typeset email_not_exists=$( is_empty --str "${mapkey}" )

    # Email address/name is new (not seen before)
    #if [ "${email_not_exists}" -eq "${YES}" ]
    #then
    #  hput --map fqea --key "${mr}" --value "${mr}@${company}"
    #  hput --map email_address --key "${mr}" --value 1
    #  mr=$( printf "%s\n" "${mr}" | tr '_' '.' )
    #  all_email_address+=";${mr}@${company}"
    #else
    #  typeset fqea_mail="$( hget --map fqea --key "${mr}" )"
    #  printf "%s\n" "${all_email_address}" | grep -q "${fqea_mail}"
    #  [ $? -ne "${PASS}" ] && all_email_address=";${fqea_mail}"
    #fi
    printf "%s\n" "${mr}" | \grep -q '@'
    if [ $? -ne "${PASS}" ]
    then
      all_email_address+=";${mr}@${company}"
    else
      all_email_address+=";${mr}"
    fi
  done

  all_email_address="$( printf "%s\n" "${all_email_address}" | \sed -e 's#;# #g' | \tr -s ' ' | \tr ' ' '\n' | \sort | \uniq | \tr '\n' ' '| \tr '_' '.'  | \sed -e 's#^,##' )"
  print_plain --message "${all_email_address}"
  return "${PASS}"
}

send_an_email()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset title=
  typeset current_user=
  typeset email_recips=
  typeset file_to_send=
  typeset company
  
  OPTIND=1
  while getoptex "t: title: u: current-user: r: email-recipients: f. file-to-send. c: company:" "$@"
  do
    case "${OPTOPT}" in
    't'|'title'            ) title="${OPTARG}";;
    'u'|'current-user'     ) current_user="${OPTARG}";;
    'r'|'email-recipients' ) email_recips+=" ${OPTARG}";;
    'f'|'file-to-send'     ) file_to_send="${OPTARG}";;
    'c'|'company'          ) company="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${file_to_send}" )" -eq "${YES}" ] && return "${FAIL}"

  company="$( default_value --def "$( __get_company )" "${company}" )"
  company="$( default_value --def 'dev.null' "${company}" )"

  if [ -n "${email_recips}" ]
  then
    typeset ae=
    typeset ae_option=
    for ae in ${email_recips}
    do
      ae_option+=" --email $( printf "%s\n" "${ae}" | \tr '.' '_' )"
    done
    email_recips="$( trim "$( build_email_list ${ae_option} --company "${company}" )" | \tr ' ' ',' )"
  fi
 
  [ "$( is_empty --str "${email_recips}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${file_to_send}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset cmd=
  #typeset email_opts=
  
  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    cmd="${mail_exe} ${__EMAIL_OPTS} -r ${company} -s \"${title}\" -n \"${current_user}\" -f \"${current_user}@${company}\" \"${email_recips}\" < \"${file_to_send}\""
  else
    if [ "$( \basename "${mail_exe}" )" == "sendmail" ]
    then
      typeset emailheader="$( printf "%s\n" "Subject:${title}" "From:${current_user}@${company}" "To:${email_recips}" )"
      typeset emailheader2="$( printf "%s\n" 'MIME-Version: 1.0' 'Content-Type: text/html' 'Content-Disposition: inline' '<html>' '<body>' '<pre style="font: monospace">' )"
      typeset emailbody="$( \cat "${file_to_send}" )"
      typeset emailfooter2="$( printf "%s\n" '</pre>' '</body>' '</html>' )"
      printf "%s\n" "${emailheader}" "${emailheader2}" "${emailbody}" "${emailfooter2}" > "${file_to_send}"
      cmd="cat \"${file_to_send}\" | ${mail_exe} -t"
    fi
    #cmd="${mail_exe} ${__EMAIL_OPTS} -r \"${current_user}@${company}\" -s \"${title}\" \"${file_to_send}\"" < \"${file_to_send}\"
  fi
  
  if [ -n "${cmd}" ]
  then
    [ "$( is_channel_in_use --channel 'CMD' )" -eq "${YES}" ] && append_output --channel 'CMD' --data "${cmd}"
    eval "${cmd}"
    RC=$?
    return "${RC}"
  else
    return "${FAIL}"
  fi
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/filemgt.sh"
fi

__initialize_emailmgt
[ $? -ne 0 ] && exit "${FAIL}"

__prepared_emailmgt
