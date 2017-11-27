#!/bin/sh
###############################################################################
# Copyright (c) 2017.  All rights reserved. 
# MIKE KLUSMAN IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, MIKE KLUSMAN IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# MIKE KLUSMAN EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
###############################################################################

###############################################################################
#
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Artifactory REST interface
## @Application      : Product Functionality
## @Language         : Bourne Shell
## @Version          : 0.83
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __get_artifact_extension
#    __get_artifact_id
#    __get_classifier_id
#    __get_group_id
#    __get_version_id
#    __reset_artifactory_settings
#    artifact_upload
#    artifact_download
#    convert_to_artifactory_coordinate
#    get_artifactory_password
#    get_artifactory_port
#    get_artifactory_protocol
#    get_artifactory_server
#    get_artifactory_user
#    set_artifactory_password
#    set_artifactory_port
#    set_artifactory_protocol
#    set_artifactory_server
#    set_artifactory_user
#
###############################################################################

# shellcheck disable=SC2039,SC2016,SC2068
if [ -z "${ARTIFACTORY_MAPNAME}" ]
then
  ARTIFACTORY_MAPNAME='ARTIFACTORY'
  artifact_management_options='f: filename: g: groupid: a: artifactid: v: versionid: c. classifier. e: extension:'
fi

__get_artifact_extension()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_artifact_extension'
  return $?
}

__get_artifact_id()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_artifactId'
  return $?
}

__get_classifier_id()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_classifier'
  return $?
}

__get_group_id()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_groupId'
  return $?
}

__get_version_id()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_versionId'
  return $?
}

__initialize_artifactory()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_base_setup "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  __load __initialize_base_logging "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  __load __initialize_rest "${SLCF_SHELL_TOP}/lib/rest.sh"
  __load __initialize_passwordmgt "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
  __load __initialize_cmdmgt "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  __load __initialize_cmd_interace "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"

  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'protocol' --value 'http' 
  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'port' --value '80'

  __initialize '__initialize_artifactory'
}

__prepared_artifactory()
{
  __prepared '__prepared_artifactory'
}

__reset_artifactory_settings()
{
  __debug $@

  hclear --map "${ARTIFACTORY_MAPNAME}"
  return $?
}

__main_artifact_management()
{
  __debug $@

  typeset artifactory_response="$( make_output_file --prefix 'ARTIFACTORY_JSON' )"
  call --cmd "$1" > "${artifactory_response}"

  cat "${artifactory_response}" >> /tmp/.xyz
  json_set_file --jsonfile "${artifactory_response}"
  
  typeset et=
  for et in ''
  do
    typeset error_type="$( json_get_matching_entry --jpath '' --match '' --field '' )"
  done
}

artifact_upload()
{
  __debug $@

  typeset RC="${PASS}"
  typeset filename=

  typeset groupid="$( __get_group_id )"
  typeset artifactid="$( __get_artifact_id )"
  typeset versionid="$( __get_version_id )"
  typeset classifier="$( __get_classifier_id )"
  typeset extension="$( __get_artifact_extension )"
  typeset use_checksums="${NO}"

  typeset prebuilt_coordinate=

  typeset otherargs=
  typeset prev="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  OPTIND=1
  while getoptex "${artifact_management_options} use-checksums coordinate:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'       ) filename="${OPTARG}";;
    'g'|'groupid'        ) groupid="${OPTARG}";;
    'a'|'artifactid'     ) artifactid="${OPTARG}";;
    'v'|'versionid'      ) versionid="${OPTARG}";;
    'c'|'classifier'     ) classifier="${OPTARG}";;
    'e'|'extension'      ) extension="${OPTARG}";;
        'coordinate'     ) prebuilt_coordinate="${OPTARG}";;
        'use-checksums'  ) use_checksums="${YES}";;
     *                   ) otherargs="${OPTOPT} ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  OPTALLOW_ALL="${prev}"

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] || [ ! -f "${filename}" ] && return "${FAIL}"

  if [ -z "${prebuilt_coordinate}" ]
  then
    [ "$( is_empty --str "${groupid}" )" -eq "${YES}" ] || [ "$( is_empty --str "${artifactid}" )" -eq "${YES}" ] && return "${FAIL}"
    [ "$( is_empty --str "${versionid}" )" -eq "${YES}" ] && versionid='1.00'
    [ "$( is_empty --str "${extension}" )" -eq "${YES}" ] && extension="$( get_extension "${filename}" )"

    typeset coordinate="$( convert_to_artifactory_coordinate -g "${groupid}" -a "${artifactid}" -c "${classifier}" -v "${versionid}" -e "${extension}" ${otherargs} )"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  fi

  typeset user="$( get_artifactory_user )"
  typeset pwd="$( get_artifactory_password )"
  typeset server="$( get_artifactory_server )"
  typeset server_path="$( get_artifactory_server_path )"
  typeset repo="$( get_artifactory_repository )"

  [ "$( is_empty --str "${user}" )" -eq "${YES}" ] || [ "$( is_empty --str "${pwd}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${server}" )" -eq "${YES}" ] || [ "${server:0:1}" == ':' ] && return "${FAIL}"
  [ "$( is_empty --str "${server_path}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${repo}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset curl_headers=
  #curl_headers+=" -H \"Authorization: Basic $( get_bare_password )\""
  if [ "${use_checksums}" -eq "${YES}" ]
  then
    typeset checksums="$( generate_checksums --filename "${filename}" )"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

    curl_headers+=" --header \"X-Checksum-Md5:$( get_element --data "${checksums}" --id 1 --separator ':' )\""
    curl_headers+=" --header \"X-Checksum-Sha1::$( get_element --data "${checksums}" --id 2 --separator ':' )\""
  fi

  typeset address="$( get_artifactory_protocol )://${server}/${server_path}/${repo}/${coordinate}"
  typeset cmd="${curl_exe} --silent --insecure --user \"${user}:${pwd}\" ${curl_headers} --request 'PUT' \"${address}\" -T \"${filename}\""

  typeset artifactory_response="$( make_output_file --prefix 'ARTIFACTORY_JSON' )"
  call --cmd "${cmd}" > "${artifactory_response}"
  RC=$?

  cat "${artifactory_response}" >> /tmp/.xyz
  #jq 
  # Need to interrogate output to see if failure should be reported
  #remove_output_file --filename "${artifactory_response}"
  return "${RC}"
}

artifact_query()
{
  __debug $@

  typeset RC="${PASS}"
  typeset filename=

  typeset groupid="$( __get_group_id )"
  typeset artifactid="$( __get_artifact_id )"
  typeset versionid="$( __get_version_id )"
  typeset classifier="$( __get_classifier_id )"
  typeset extension="$( __get_artifact_extension )"

  typeset otherargs=
  typeset prev="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  OPTIND=1
  while getoptex "g: groupid: a: artifactid: v: versionid: c. classifier. e: extension:" "$@"
  do
    case "${OPTOPT}" in
    'g'|'groupid'        ) groupid="${OPTARG}";;
    'a'|'artifactid'     ) artifactid="${OPTARG}";;
    'v'|'versionid'      ) versionid="${OPTARG}";;
    'c'|'classifier'     ) classifier="${OPTARG}";;
    'e'|'extension'      ) extension="${OPTARG}";;
     *                   ) otherargs="${OPTOPT} ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  OPTALLOW_ALL="${prev}"

  [ "$( is_empty --str "${groupid}" )" -eq "${YES}" ] || [ "$( is_empty --str "${artifactid}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${versionid}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${extension}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset coordinate="$( convert_to_artifactory_coordinate -g "${groupid}" -a "${artifactid}" -c "${classifier}" -v "${versionid}" -e "${extension}" ${otherargs} )"
  RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    typeset user="$( get_artifactory_user )"
    typeset pswd="$( get_artifactory_password )"
    typeset server="$( get_artifactory_server )"
    typeset server_path="$( get_artifactory_server_path )"
    typeset repo="$( get_artifactory_repository )"

    [ "$( is_empty --str "${user}" )" -eq "${YES}" ] || [ "$( is_empty --str "${pswd}" )" -eq "${YES}" ] && return "${FAIL}"
    [ "$( is_empty --str "${server}" )" -eq "${YES}" ] || [ "${server:0:1}" == ':' ] && return "${FAIL}"
    [ "$( is_empty --str "${server_path}" )" -eq "${YES}" ] && return "${FAIL}"
    [ "$( is_empty --str "${repo}" )" -eq "${YES}" ] && return "${FAIL}"

    typeset curl_headers=
    if [ "${use_checksums}" -eq "${YES}" ]
    then
      curl_headers+=" --header \"X-Checksum-Md5:$( get_element --data "${checksums}" --id 1 --separator ':' )\""
      curl_headers+=" --header \"X-Checksum-Sha1::$( get_element --data "${checksums}" --id 2 --separator ':' )\""
    fi

    typeset address="$( get_artifactory_protocol )://${server}/${server_path}/${repo}/${coordinate}"
    typeset cmd="${curl_exe} --silent --insecure --user \"${user}:${pwd}\" --output \"${filename}\" \"${address}\""

    typeset artifactory_response="$( make_output_file )"
    call --cmd "${cmd}" > "${artifactory_response}"
    RC=$?

    #jq
    # Need to interrogate output to see if failure should be reported
    #remove_output_file --filename "${artifactory_response}"
  fi
  return "${RC}"
}

artifact_download()
{
  __debug $@

  typeset RC="${PASS}"
  typeset filename=

  typeset groupid="$( __get_group_id )"
  typeset artifactid="$( __get_artifact_id )"
  typeset versionid="$( __get_version_id )"
  typeset classifier="$( __get_classifier_id )"
  typeset extension="$( __get_artifact_extension )"

  typeset otherargs=
  typeset prev="${OPTALLOW_ALL}"
  OPTALLOW_ALL="${YES}"
  OPTIND=1
  while getoptex "f: filename: g: groupid: a: artifactid: v: versionid: c. classifier. e: extension:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename'       ) filename="${OPTARG}";;
    'g'|'groupid'        ) groupid="${OPTARG}";;
    'a'|'artifactid'     ) artifactid="${OPTARG}";;
    'v'|'versionid'      ) versionid="${OPTARG}";;
    'c'|'classifier'     ) classifier="${OPTARG}";;
    'e'|'extension'      ) extension="${OPTARG}";;
     *                   ) otherargs="${OPTOPT} ${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  OPTALLOW_ALL="${prev}"

  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && filename='download_output'
  [ "$( is_empty --str "${groupid}" )" -eq "${YES}" ] || [ "$( is_empty --str "${artifactid}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${versionid}" )" -eq "${YES}" ] && versionid='1.00'
  [ "$( is_empty --str "${extension}" )" -eq "${YES}" ] && extension="$( get_extension "${filename}" )"

  typeset coordinate="$( convert_to_artifactory_coordinate -g "${groupid}" -a "${artifactid}" -c "${classifier}" -v "${versionid}" -e "${extension}" ${otherargs} )"
  RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    typeset user="$( get_artifactory_user )"
    typeset pswd="$( get_artifactory_password )"
    typeset server="$( get_artifactory_server )"
    typeset server_path="$( get_artifactory_server_path )"
    typeset repo="$( get_artifactory_repository )"

    [ "$( is_empty --str "${user}" )" -eq "${YES}" ] || [ "$( is_empty --str "${pswd}" )" -eq "${YES}" ] && return "${FAIL}"
    [ "$( is_empty --str "${server}" )" -eq "${YES}" ] || [ "${server:0:1}" == ':' ] && return "${FAIL}"
    [ "$( is_empty --str "${server_path}" )" -eq "${YES}" ] && return "${FAIL}"
    [ "$( is_empty --str "${repo}" )" -eq "${YES}" ] && return "${FAIL}"

    typeset address="$( get_artifactory_protocol )://${server}/${server_path}/${repo}/${coordinate}"
    typeset cmd="${curl_exe} --silent --insecure --user \"${user}:${pwd}\" --output \"${filename}\" \"${address}\""

    __main_artifact_management "${cmd}"
    RC=$?
  fi
  return "${RC}"
}

convert_to_artifactory_coordinate()
{
  __debug $@

  typeset RC="${PASS}"

  typeset groupid=
  typeset artifactid=
  typeset versionid=
  typeset classifier=
  typeset extension=
  typeset use_vID_in_name="${NO}"

  OPTIND=1
  while getoptex "g: groupid: a: artifactid: v: versionid: c. classifier. e: extension: add-version-to-name" "$@"
  do
    case "${OPTOPT}" in
    'g'|'groupid'             ) groupid="${OPTARG}";;
    'a'|'artifactid'          ) artifactid="${OPTARG}";;
    'v'|'versionid'           ) versionid="${OPTARG}";;
    'c'|'classifier'          ) classifier="${OPTARG}";;
    'e'|'extension'           ) extension="${OPTARG}";;
        'add-version-to-name' ) use_vID_in_name="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -n "${groupid}" ] && set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_groupId' --value "${groupid}"
  typeset gID="$( __get_group_id )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ -n "${artifactid}" ] && set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_artifactId' --value "${artifactid}"
  typeset aID="$( __get_artifact_id )"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print "%s\n" "${gID}"
    return "${FAIL}"
  fi

  [ -n "${versionid}" ] && set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_versionId' --value "${versionid}"
  typeset vID="$( __get_version_id )"
  RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print "%s\n" "${gID}/${aID}"
    return "${FAIL}"
  fi

  [ -n "${classifier}" ] && set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_classifier' --value "${classifier}"
  [ -n "${extension}" ] && set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'last_artifact_extension' --value "${extension}"
  typeset cID="$( __get_classifier_id )"
  typeset extension="$( __get_artifact_extension )"

  typeset baselevel="${aID}"
  [ "${use_vID_in_name}" -eq "${YES}" ] && baselevel+="-${vID}"

  [ -n "${cID}" ] && baselevel+="-${cID}"
  if [ -n "${extension}" ]
  then
    if [ "${extension:0:1}" == '.' ]
    then
      baselevel+="${extension}"
    else
      baselevel+=".${extension}"
    fi
  fi

  printf "%s\n" "${gID}/${aID}/${vID}/${baselevel}"
  return "${PASS}" 
}

get_artifactory_password()
{
  __debug $@

  full_decode "$( get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'password' )"
  return $?
}

get_artifactory_port()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'port'
  return $?
}

get_artifactory_protocol()
{
  __debug $@

  typeset current_setting="$( get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'protocol' )"
  typeset prot=" $( default_value --def 'http' "${current_setting}" )"
  printf "%s\n" "$( trim ${prot} )"
  return $?
}

get_artifactory_repository()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'repository'
  return $?
}

get_artifactory_server()
{
  __debug $@

  typeset server_name="$( get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'server' )"
  typeset port="$( get_artifactory_port )"

  if [ -n "${port}" ]
  then
    printf "%s\n" "${server_name}:${port}"
  else
    printf "%s\n" "${server_name}"
  fi
  return $?
}

get_artifactory_server_path()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'server_path'
  return $?
}

get_artifactory_user()
{
  __debug $@

  get_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'user'
  return $?
}

set_artifactory_password()
{
  __debug $@

  typeset passwd=

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) passwd="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${passwd}" ] && return "${FAIL}"

  ### No decryption here -- only when retrieved
  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'password' --value "${passwd}"
  return $?
}

set_artifactory_port()
{
  __debug $@

  typeset port=

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) port="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${port}" )" -eq "${YES}" ]
  then
    delete_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'port'
    return $?
  elif [ "$( is_numeric_data --data "${port}" )" -eq "${NO}" ]
  then
    #print_msg --channel ERROR --message "Non numeric data for port discovered.  Skipping!"
    return "${FAIL}"
  else
    if [ "${port}" -gt 0 ] && [ "${port}" -lt 65536 ]
    then
      set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'port' --value "${port}"
      return $?
    fi
  fi
  return "${FAIL}"
}

set_artifactory_protocol()
{
  __debug $@

  typeset protocol='http'

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) protocol="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'protocol' --value "${protocol}"
  return $?
}

set_artifactory_repository()
{
  __debug $@

  typeset repo=

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) repo="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${repo}" ] && return "${FAIL}"

  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'repository' --value "${repo}"
  return $?
}

set_artifactory_server()
{
  __debug $@

  typeset server=

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) server="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${server}" ] && return "${FAIL}"
  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'server' --value "${server}"
  return $?
}

set_artifactory_server_path()
{
  __debug $@

  typeset serverpath='artifactory/api/storage'

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) serverpath="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'server_path' --value "${serverpath}"
  return $?
}

set_artifactory_user()
{
  __debug $@

  typeset user=

  OPTIND=1
  while getoptex "v: value:" "$@"
  do
    case "${OPTOPT}" in
    'v'|'value' ) user="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${user}" ] && return "${FAIL}"
  set_rest_api_db --map "${ARTIFACTORY_MAPNAME}" --key 'user' --value "${user}"
  return $?
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'

if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_setup.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_logging.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/rest.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/passwordmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"
fi

__initialize_artifactory
__prepared_artifactory
