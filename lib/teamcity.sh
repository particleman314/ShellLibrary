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
# Software Package : Shell Automated Testing -- TeamCity
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __extract_storage_directory
#    __get_teamcity_xml_rootpath
#    __get_teamcity_rest_address
#    __get_teamcity_rest_address_port
#    __get_storage_area
#    __set_teamcity_xml_rootpath
#    __set_teamcity_rest_address
#    __set_teamcity_rest_address_port
#    __set_storage_area
#    check_teamcity_job
#    download_from_teamcity
#    email_teamcity_download
#    rename_oldest_teamcity_downloads
#    unpack_teamcity_download
#    verify_teamcity_download
#
###############################################################################

[ -z "${__TC_MAP}" ] && __TC_MAP=

__initialize_teamcity()
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

  __initialize "__initialize_teamcity"
}

__prepared_teamcity()
{
  __prepared "__prepared_teamcity"
}

__extract_storage_directory()
{
  typeset xmlfile=
  typeset rootnode=
  typeset islocal="${NO}"
  typeset RC=

  OPTIND=1
  while getoptex "x: xmlfile: r: xml-rootpath: l: local:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlfile'       ) xmlfile="${OPTARG}";;
    'r'|'xml-rootpath'  ) rootnode="${OPTARG}";;
    'l'|'local'         ) islocal="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${xmlfile}" ) -eq "${YES}" ] && xmlfile=$( xml_get_file )
  [ $( is_empty --str "${rootnode}" ) -eq "${YES}" ] && rootnode=$( __get_teamcity_xml_rootpath )

  [ $( is_empty --str "${xmlfile}" ) -eq "${YES}" ] && [ $( is_empty --str "${rootnode}" ) -eq "${YES}" ] && return "${FAIL}"

  if [ "${islocal}" -eq "${YES}" ]
  then
    storage="$( xml_get_single_entry --xpath "${rootnode}/storage_area" --xmlfile "${xmlfile}" --field 'local' )"
    [ $( is_empty --str "${storage}" ) -eq "${YES}" ] && storage=$( make_temp_dir )
    printf "%s\n" "${storage}"
  else
    typeset subtarget_xmlfile=$( xml_get_subxml --xmlfile "${xmlfile}" --xpath "${rootnode}/storage_area/remote[@OS='${OSVARIETY}']" )
    RC=$?
    [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subtarget_xmlfile}" ] && return "${FAIL}"
    typeset storage="$( xml_get_single_entry --xpath 'remote' --xmlfile "${subtarget_xmlfile}" --field 'fileshare' )"
    [ $( is_empty --str "${storage}" ) -eq "${YES}" ] && return "${FAIL}"
    printf "%s\n" "${storage}"
  fi
  return "${PASS}"
}

__get_teamcity_xml_rootpath()
{
  hget --map '__TC_MAP' --key 'xml_rootpath'
  return $?
}

__get_teamcity_rest_address()
{
  $( __get_rest_api_address $@ )
  return $?
}

__get_teamcity_rest_address_port()
{
  $( __get_rest_api_address_port $@ )
  return $?
}

__get_storage_area()
{
  hget --map '__TC_MAP' --key 'storage_area'
  return $? 
}

__set_teamcity_xml_rootpath()
{
  typeset rp="$1"

  if [ -z "${rp}" ]
  then
    hdel --map '__TC_MAP' --key 'xml_rootpath'
  else
    hput --map '__TC_MAP' --key 'xml_rootpath' --value "${rp}"
  fi
  return $?
}

__set_teamcity_rest_address()
{
  $( __set_rest_api_address $@ )
  return $?
}

__set_teamcity_rest_address_port()
{
  $( __set_rest_api_address_port $@ )
  return $?
}

__set_storage_area()
{
  typeset sa="$1"
  typeset needs_creation="${2:-0}"

  if [ -z "${sa}" ]
  then
    hdel --map '__TC_MAP' --key 'storage_area'
    return $?
  else
    if [ "${needs_creation}" -eq 0 ]
    then
      [ -d "${sa}" ] && hput --map '__TC_MAP' --key 'storage_area' --value "${sa}"
    else
      mkdir -p "${sa}"
      hput --map '__TC_MAP' --key 'storage_area' --value "${sa}"
    fi
    return $?
  fi
}

get_build_agents()
{
  typeset user_id=
  typeset passwd=
  typeset passwd_decode="${NO}"
  typeset rawmode="${NO}"
  
  OPTIND=1
  while getoptex "u: user-id: p: passwd: d decode r raw" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user-id'       ) user_id="${OPTARG}";;
    'p'|'passwd'        ) passwd="${OPTARG}";;
    'd'|'decode'        ) passwd_decode="${YES}";;
    'r'|'raw'           ) rawmode="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${user_id}" ) -eq "${YES}" ] && return "${FAIL}"  
  [ $( is_empty --str "${passwd}") -eq "${YES}" ] && return "${FAIL}"
  
  typeset cmdoptions="--user-id \"${user_id}\" --passwd=\"${passwd}\""
  [ "${passwd_deocde}" -eq "${YES}" ] && cmdoptions+=" --decode"
  
  typeset addr=$( __get_teamcity_rest_address 'TEAMCITY' )
  [ $( is_empty --str "${addr}" ) -eq "${YES}" ] && return "${FAIL}"
  
  typeset output=$( run_rest_api ${cmdoptions} --cmd "${addr}/agents" )
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  [ "${rawmode}" -eq "${NO}" ] && printf "%s\n" "${output}" | ${xml_exe} format
  return "${RC}"
}

check_teamcity_job()
{
  typeset jobID=
  typeset user_id=
  typeset passwd=
  typeset tc_locator=
  typeset status='UNKNOWN'
  typeset timeout=-1

  OPTIND=1
  while getoptex "j: job-id: u: user_id: p: passwd: l: locator: t: timeout:" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user_id'      ) user_id="${OPTARG}";;
    'p'|'passwd'       ) password="${OPTARG}";;
    'j'|'job-id'       ) jobID="${OPTARG}";;
    'l'|'locator'      ) tc_locator="${OPTARG}";;
    't'|'timeout'      ) timeout="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${TC_BASE_HTTP_ADDRESS}" ] && return "${FAIL}"
  [ "${timeout}" -le 0 ] && timeout=-1

  [ $( is_empty --str "${jobID}" ) -eq "${YES}" ] || [ $( is_empty --str "${user-id}" ) -eq "${YES}" ] || [ $( is_empty --str "${passwd}" ) -eq "${YES}" ] || [ $( is_empty --str "${tc_locator}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset count=0
  
  while [ "${status}" -ne 'SUCCESS' ] || [ "${status}" -ne 'FAILED' ]
  do
    if [ "${timeout}" -gt 0 ]
    then
      count=$( increment ${count} )
      [ "${count}" -ge "${timeout}" ] && break
    fi
    typeset tc_rest_addr=$( get_teamcity_rest_address )
    typeset output=$( ${wget_exe} --user "${user_id}" --password "${passwd}" "${TC_BASE_HTTP_ADDRESS}/${tc_rest_addr}?locator=${locator} $@" )
    append_output --channel 'TC_QUERY' --data "${output}" --raw
    typeset latest=$( xml_get_multi_entry --xmlfile "$( find_output_file --channel 'TC_QUERY' )" --xpath '/builds/build' -f '@status' -f ':' -f '@number' -f ' ' )
    status=$( get_element --data "$( print_plain --message "${latest}" )" --id 1 --separator ':' )
    remove_output_file --channel 'TC_QUERY'

    sleep_func -s 1 --old-version
  done

  [ "${status}" == 'SUCCESS' ] && return "${PASS}" || return "${FAIL}"
}

download_from_teamcity()
{
  __debug $@

  typeset storage_dir=
  typeset user_id=
  typeset passwd=
  typeset tag=
  typeset branch=
  typeset probe_type=
  typeset compile_style='cmake'
  typeset output_download_file='output.zip'

  typeset xmlfile=
  typeset rootpath=
  typeset rest_path=
  typeset RC

  OPTIND=1
  while getoptex "c: compile-style: s: storage-dir: u: user-id: p: passwd: t: tag: b: branch: t: type: x: xmlfile: r: xml-rootpath: tc-rest-path: o: outputfile:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'compile-style' ) compile_style="${OPTARG}";;
    's'|'storage-dir'   ) storage_dir="${OPTARG}";;
    'u'|'user-id'       ) user_id="${OPTARG}";;
    'p'|'passwd'        ) passwd=$( decode_passwd "${OPTARG}" );;
    't'|'tag'           ) tag="${OPTARG}";;
    'b'|'branch'        ) branch="${OPTARG}";;
    't'|'type'          ) probe_type="${OPTARG}";;
    'x'|'xmlfile'       ) xmlfile="${OPTARG}";;
    'r'|'xml-rootpath'  ) rootpath="${OPTARG}";;
    'o'|'outputfile'    ) output_download_file="${OPTARG}";;
        'tc-rest-path'  ) rest_path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset maxkeep=0
  typeset webaddr
  typeset tc_coordinate

  [ $( is_empty --str "${branch}" ) -eq "${YES}" ] && return "${FAIL}"
  [ $( is_empty --str "${probe_type}" ) -eq "${YES}" ] && return "${FAIL}"

  if [ -n "${xmlfile}" ]
  then
    __disable_xml_failure
    xml_check_file --xmlfile "${xmlfile}"
    RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      xml_set_file --xmlfile "${xmlfile}"
      rootpath=$( default_value --def "$( hget --map '__TC_MAP' --key 'xml_rootpath' )" "${rootpath}" )

      if [ -z "${rootpath}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --blurb "No defined rootnode path for xmlfile < ${xmlfile} >"
        return "${FAIL}"
      fi

      maxkeep=$( default_value "$( xml_get_single_entry --xpath "${rootpath}/storage_area" --field 'keep_limit' )" --def "${maxkeep}" )

      ################################################################
      # Basic information generic to any branch
      ################################################################
      typeset xmlstorage="$( __extract_storage_directory --xmlfile "${xmlfile}" --xml-rootpath "${rootpath}" )"
      storage_dir=$( default_value --def "${xmlstorage}" "${storage_dir}" )
      RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --blurb 'No storage area found matching request'
        return "${FAIL}"
      fi

      user_id=$( default_value --def "$( xml_get_single_entry --xpath "${rootpath}/build_server" --field 'username' )" "${user_id}" )
      passwd=$( default_value --def "$( decode_passwd "$( xml_get_single_entry --xpath "${rootpath}/build_server" --field 'password' )" )" "${passwd}" )
      tag=$( default_value --def "$( xml_get_single_entry --xpath "${rootpath}/build_server" --field 'tag_marker' )" "${tag}" )
      webaddr=$( default_value --def "$( xml_get_single_entry --xpath "${rootpath}/build_server" --field 'http_address' )" "$( __get_teamcity_rest_address )" )

      if [ -z "${webaddr}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${pkg_name}:${user_id}" --blurb 'No web address defined'
        return "${FAIL}"
      fi

      ################################################################
      # Branch information when accessing TeamCity
      ################################################################
      typeset subtarget_xmlfile=$( xml_get_subxml --xmlfile "${xmlfile}" --xpath "${rootpath}/build_server/projects/project[@probe='${probe_type}'][@compile_style='${compile_style}']" )
      RC=$?
      if [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subtarget_xmlfile}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --blurb "Could not find requested branch < ${branch} >"
        return "${FAIL}"
      fi

      typeset project_name="$( xml_get_single_entry --xpath "/project" --field 'name' --xmlfile "${subtarget_xmlfile}" )"
      typeset known_branches=$( xml_get_multi_entry --format "%s" --xpath '/project/branches/branch' --xmlfile "${subtarget_xmlfile}" --field '@name' )
      typeset kb
      typeset found_match="${NO}"
      for kb in ${known_branches}
      do
        if [ "${kb}" == "${branch}" ]
        then
          found_match="${YES}"
          break
        fi
      done

      if [ "${found_match}" -eq "${NO}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --blurb "Could not find requested branch < ${branch} >"
        return "${FAIL}"
      fi

      subtarget_xmlfile=$( xml_get_subxml --xmlfile "${subtarget_xmlfile}" --xpath "/project/branches/branch[@name='${branch}']" )
      RC=$?
      if [ "${RC}" -ne "${PASS}" ] || [ ! -f "${subtarget_xmlfile}" ]
      then
        email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --blurb "Could not find requested branch < ${branch} >"
        return "${FAIL}"
      fi

      ################################################################
      # Branch specifics to complete access via TeamCity
      ################################################################
      rest_path=$( default_value --def "$( xml_get_single_entry --xpath '/branch' --field 'content_path' --xmlfile "${subtarget_xmlfile}" )" "${rest_path}" )
      output_download_file=$( default_value --def "$( xml_get_single_entry --xpath '/branch' --field 'downloadfile' --xmlfile "${subtarget_xmlfile}" )" "${output_download_file}" )
    fi
    tc_coordinate="${webaddr}/${rest_path}/${project_name}/${tag}?branch=${branch}"
  else
    tc_coordinate="$( __get_teamcity_rest_address )/${rest_path}/${tag}?branch=${branch}"
  fi

  if [ $( is_empty --str "${user_id}" ) -eq "${YES}" ] || [ $( is_empty --str "${passwd}" ) -eq "${YES}" ]
  then
    email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" 'No user ID or password defined'
    return "${FAIL}"
  fi

  #[ -n "${storage_dir}" ] && [ -d "${storage_dir}/${branch}/${probe_type}" ] && rename_oldest_teamcity_downloads --storage-dir "${storage_dir}/${branch}/${probe_type}" --maxkeeps "${maxkeep}"
  [ ! -d "${storage_dir}/${branch}/${probe_type}" ] && mkdir -p "${storage_dir}/${branch}/${probe_type}"

  typeset wget_outfile=$( make_output_file --channel 'WGET_OUTPUT' )
  wget --user="${user_id}" --password="${passwd}" --no-verbose --backups="${maxkeep}" "${tc_coordinate}" -O "${storage_dir}/${branch}/${probe_type}/${output_download_file}" > "${wget_outfile}" 2>&1
  RC=$?
  append_output --channel 'CMDS' --data "wget --user=\"${user_id}\" --password=\"${passwd}\" --no-verbose --backups=\"${maxkeep}\" \"${tc_coordinate}\" -O \"${storage_dir}/${branch}/${probe_type}/${output_download_file}\""

  scan_for_errors --channel 'WGET_OUTPUT' --regex "[Ee][Rr][Rr][Oo][Rr]"
  typeset scanRC=$?

  if [ "${RC}" -ne "${PASS}" ] || [ "${scanRC}" -ne "${PASS}" ] || [ ! -f "${storage_dir}/${branch}/${probe_type}/${output_download_file}" ] && [ -s "${storage_dir}/${branch}/${probe_type}/${output_download_file}" ]
  then
    append_output --channel 'TC_WGET' --data "Unable to download ${probe_type} build from branch : ${branch}" --raw
    append_output --channel 'TC_WGET' --data "Output from (wget) [ error-code --> ${RC} ]" --raw
    append_output --channel 'TC_WGET' --data "${wget_output}" --raw

    typeset failure_file=$( find_output_file --channel 'TC_WGET' )
    email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${probe_type}:${user_id}" --datafile "${failure_file}"
    remove_output_file --channel 'TC_WGET'
    return "${FAIL}"
  fi

  return "${PASS}"
}

email_teamcity_download()
{
  __debug $@

  typeset errortype=
  typeset info=
  typeset filename
  typeset blurb=

  typeset RC

  OPTIND=1
  while getoptex "t: type: c: coordinates: d: datafile: b: blurb:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'coordinates'   ) info="${OPTARG}";;
    't'|'type'          ) errortype="${OPTARG}";;
    'd'|'datafile'      ) filename="${OPTARG}";;
    'b'|'blurb'         ) blurb="$OPTARG}";;
    'e'|'email-members' ) email_members+=",${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${info}" ) -eq "${YES}" ] && return "${FAIL}"

  typeset tag=$( get_element --data "${info}" --id 1 --separator ':' )
  typeset branch=$( get_element --data "${info}" --id 2 --separator ':' )
  typeset pkg=$( get_element --data "${info}" --id 3 --separator ':' )
  typeset user=$( default_value $( get_element --data "${info}" --id 4 --separator ':' ) 'root' )

  typeset tag_statement
  typeset branch_statement
  typeset pkg_statement

  if [ -z "${tag}" ]
  then
    tag_statement='No tag was used for determination of the TeamCity build'
    errortype=${errortype:-'FAIL'}
  else
    tag_statement="Tag ${tag} of branch was requested from TeamCity"
  fi

  if [ -z "${branch}" ]
  then
    branch_statement='No branch was used for determinaton of TeamCity build'
    errortype=${errortype:-'FAIL'}
  else
    branch_statement="Branch ${branch} was requested from TeamCity"
  fi

  if [ -z "${pkg}" ]
  then
    pkg_statement='No package was requested of TeamCity build'
    errortype=${errortype:-'FAIL'}
  else
    pkg_statement="Package ${pkg} was requested from TeamCity"
  fi

  [ $( is_empty --str "${errortype}" ) -eq "${YES}" ] && errortype='SUCCESS'

  typeset email_file=$( make_output_file --channel 'TC_EMAIL' )

  append_output --channel 'TC_EMAIL' --raw --data "${tag_statement}"
  append_output --channel 'TC_EMAIL' --raw --data "${branch_statement}"
  append_output --channel 'TC_EMAIL' --raw --data "${pkg_statement}"
  append_output --channel 'TC_EMAIL' --raw --data "Result : ${errortype}"

  [ -n "${blurb}" ] && append_output --channel 'TC_EMAIL' --raw --data "Blurb : ${blurb}"
  [ -n "${filename}" ] || [ -f "${filename}" ] && append_output --channel 'TC_EMAIL' --raw --data "$( cat "${filename}" )" 

  __set_company '.ca.com'
  typeset maintenance=$( __get_maintainer )

  [ -z "${email_members}" ] && email_members="${maintenance}" || email_members="${email_members},${maintenance}"

  send_an_email --title "${errortype} for build download from TeamCity" --current-user='SLCF_AUTOMATED_DOWNLOAD' --email-recipients "${email-members}" --file-to-send "${email_file}"
  remove_output_file --channel 'TC_EMAIL'
  return "${PASS}"
}

rename_oldest_teamcity_downloads()
{
  __debug $@

  typeset storage_dir
  typeset maxkeeps=0
  typeset RC

  OPTIND=1
  while getoptex "s: storage-dir: m: maxkeeps:" "$@"
  do
    case "${OPTOPT}" in
    's'|'storage-dir'  ) storage_dir="${OPTARG}";;
    'm'|'maxkeeps'     ) maxkeeps="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${storage_dir}" ] || [ ! -d "${storage_dir}" ] && return "${FAIL}"
  [ "${maxkeeps}" -lt 1 ] && return "${PASS}"

  typeset entries=$( ls -1rt "${storage_dir}" 2>&1 )
  typeset num_entries=$( count_items --data "${entries}" )

  if [ "${num_entries}" -gt "${maxkeep}" ]
  then
    typeset differential=$( printf "%s\n" "${num_entries} - ${maxkeeps}" | bc )
    typeset oldest=$( printf "%s\n" ${entries} | head -n ${differential} )

    typeset e
    for e in ${oldest}
    do
      [ -d "${oldest}" ] && rm -rf "${oldest}"
    done
  fi
}

unpack_teamcity_download()
{
  __debug $@

  typeset output_dir
  typeset compressfile
  typeset xmlfile
  typeset RC

  OPTIND=1
  while getoptex "o: output-dir: c: compress-file:i x: xmlfile:" "$@"
  do
    case "${OPTOPT}" in
    'o'|'output-dir'     ) output_dir="${OPTARG}";;
    'c'|'compress-file'  ) compressfile="${OPTARG}";;
    'x'|'xmlfile'        ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ $( is_empty --str "${compressfile}" ) -eq "${YES}" ] || [ ! -f "${compressfile}" ] && return "${FAIL}"

  if [ -n "${xmlfile}" ]
  then
    xml_check_file --xmlfile "${xmlfile}"
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  typeset root_unpack_path=$( default_value "${TC_XML_DRIVER_ROOT_PATH}" "${rootpath:-/unpack_teamcity_build}" )

  typeset dcmp_opts=
  typeset decompression_pwd=$( decode_passwd $( xml_get_single_entry --xmlfile "${xmlfile}" --xpath "${root_unpack_path}" --field 'tc_password' ) )
  [ $( is_empty --str "${decompression_pwd}" ) -eq "${NO}" ] && dcmp_opts+=" -p \"${decompression_pwd}\""
  decompress --compress-file "${compressfile}" --decompressor unzip ${dcmp_opts}
}

verify_teamcity_download()
{
  __debug $@

  typeset probe_type
  typeset compress_dir
  typeset RC

  OPTIND=1
  while getoptex "c: compress-dir: p: type: x: xmlfile:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'compress-dir'  ) compress_dir="${OPTARG}";;
    'p'|'type'          ) probe_type="${OPTARG}";;
    'x'|'xmlfile'       ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -n "${xmlfile}" ]
  then
    xml_check_file --xmlfile "${xmlfile}"
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      printf "%d" "${NO}"
      return "${FAIL}"
    fi
  fi

  if [ -z "${compress_dir}" ] || [ ! -d "${compress_dir}" ]
  then
    printf "%d" "${NO}"
    return "${FAIL}"
  fi

  typeset root_inflate_path=$( default_value "${TC_XML_DRIVER_ROOT_PATH}" "${rootpath:-/unpack_teamcity_build}" )

  typeset subxmlfile=$( xml_get_subxml --xpath "${root_inflate_path}/${probe_type}" --xmlfile "${xmlfile}" )
  if [ -f "${subxmlfile}" ]
  then
    typeset artifacts=$( xml_get_single_entry --xpath "${root_inflate_path}/${probe_type}" --field 'artifacts' )
    typeset dcmp_opts=
    typeset decompression_pwd=$( decode_passwd $( xml_get_single_entry --xpath "${root_unpack_path}" --field 'archive_password' ) )
    [ $( is_empty --str "${decompression_pwd}" ) -eq "${NO}" ] && dcmp_opts+=" -p \"${decompression_pwd}\""

    typeset a
    for a in ${artifacts}
    do
      typeset loctmpdir=$( make_temp_dir )
      decompress --compress-file "${compressfile}" --decompressor unzip ${dcmp_opts} --output-dir "${loctmpdir}"
      RC=$?
      if [ "${RC}" -ne "${PASS}" ]
      then
        hadd_item --map "${probe_type}_unpack" --key 'failed_unpack' --value "${a}"
        hinc --map "${probe_type}_unpack" --key 'num_failed_unpackings'
        continue
      else
        typeset expected_comps=$( xml_get_single_entry --xpath "${root_inflate_path}/${probe_type}/artifact_components" --field 'entries' )
        typeset e
        for e in ${entries}
        do
          if [ ! -e "${loctmpdir}/${e}" ]
          then
            hadd_item --map "${probe_type}_unpack" --key 'missing_artifact' --value "${e}"
            hinc --map "${probe_type}_unpack" --key 'num_missing_artifacts'
          fi
        done
      fi
      rm -rf "${loctmpdir}"
    done

    rm -f "${subxmlfile}"

    typeset num_failures=0
    typeset num_fail_packings=$( hget --map "${probe_type}_unpack" --key 'num_failed_unpackings' )
    typeset num_miss_artifacts=$( hget --map "${probe_type}_unpack" --key 'num_missing_artifacts' )

    num_failures=$( increment ${num_failures} ${num_fail_packings:-0} )
    num_failures=$( increment ${num_failures} ${num_miss_artifacts:-0} )

    if [ "${num_failures}" -gt 0 ]
    then
      append_output --channel 'TC_UNPACK' --data "Unable to unpack ${probe_type} build from TeamCity properly..." --raw
      append_output --channel 'TC_UNPACK' --data "Number of unpacking failures observed : ${num_failures}" --raw

      [ -n "${num_fail_packings}" ] && [ "${num_fail_packings}" -gt 0 ] && append_output --channel 'TC_UNPACK' --data "  --> Failed Unpackings : ${num_fail_packings}" --raw
      [ -n "${num_miss_artifacts}" ] && [ "${num_miss_artifacts}" -gt 0 ] && append_output --channel 'TC_UNPACK' --data "  --> Missing Artifacts : ${num_miss_artifacts}" --raw

      typeset failure_file=$( find_output_file --channel 'TC_UNPACK' )
      email_teamcity_download --type 'FAILURE' --coordinates "${tag}:${branch}:${pkg_name}:${user_id}" --datafile "${failure_file}"
      remove_output_file --channel 'TC_UNPACK'
      print_no
    else
      print_yes
    fi
    return "${PASS}"
  else
    print_no
    return "${PASS}"
  fi
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_FUNCTIONDIR}/passwordmgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/stringmgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/networkmgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/xmlmgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/hashmaps.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/emailmgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/machinemgt.sh"
  . "${SLCF_SHELL_FUNCTIONDIR}/logging.sh"
fi

__initialize_teamcity
__prepared_teamcity

