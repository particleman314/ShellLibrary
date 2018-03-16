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
## @Software Package : Shell Automated Testing -- XML Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.33
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __disable_xml_failure
#    __enable_xml_failure
#    __xml_generate_header
#    __xml_suppression
#    xml_check_file
#    xml_count_entries
#    xml_delete_entry
#    xml_edit_entry
#    xml_exists
#    xml_fail
#    xml_generate_new_file
#    xml_get_attribute
#    xml_get_channel
#    xml_get_file
#    xml_get_matching_entry
#    xml_get_multi_entry
#    xml_get_rootnode_name
#    xml_get_text
#    xml_get_single_entry
#    xml_get_subxml
#    xml_has_attribute
#    xml_has_node
#    xml_merge
#    xml_node_processor
#    xml_select_entry
#    xml_set_file
#    xml_set_output_channel
#    xml_set_output_file
#    xml_unset_file
#    xml_validate
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC2068,SC1117,SC2086,SC2181,SC2034

__disable_xml_failure()
{
  typeset setting="${1:-${YES}}"

  if [ -z "${__XML_FAILURE_SUPPRESSION}" ]
  then
    __XML_FAILURE_SUPPRESSION="${YES}"
  else
    __XML_FAILURE_SUPPRESSION="$(( __XML_FAILURE_SUPPRESSION + setting ))"
  fi

  __XML_FAILURE_SUPPRESSION="$( __range_limit "${__XML_FAILURE_SUPPRESSION}" "${NO}" "${YES}" )"
}

__enable_xml_failure()
{
  __XML_FAILURE_SUPPRESSION="${NO}"
}

__initialize_xmlmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( ${__REALPATH} "${__REALPATH_OPTS}" "$( \dirname '$0' )" )

  # Requires xmlstarlet to be available on the system
  __load __initialize_xmlmgt "${SLCF_SHELL_TOP}/lib/base_logging.sh"

  [ -z "${__STD_XMLFILE}" ] && __STD_XMLFILE=
  
  __XML_TRACING_CHANNEL='XML'
  __XML_TRACING_FILE=

  __initialize "__initialize_xmlmgt"
}

__prepared_xmlmgt()
{
  __prepared "__prepared_xmlmgt"
}

__xml_generate_header()
{
  printf "%s\n" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  return "${PASS}"
}

__xml_suppression()
{
  typeset msg="$1"

  [ "$( is_empty --str "${msg}" )" -eq "${YES}" ] && return "${PASS}"

  if [ "${__XML_FAILURE_SUPPRESSION}" -eq "${NO}" ]
  then
    print_plain --message "[ ERROR ] ${msg}"
    append_output --channel 'ERROR' --data "${msg}"
  elif [ "${__XML_FAILURE_SUPPRESSION}" -eq "${YES}" ]
  then
    append_output --channel 'ERROR' --data "${msg}"
  fi

  return "${PASS}"
}

__xml_transform()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset transformer=
  
  OPTIND=1
  while getoptex "p: xpath: x. xmlfile. t: transform:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    't'|'transform' ) transformer="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset output="$( ${xml_exe} sel -t -c "${transformer}(${xpath})" ${details} "${xmlfile}" )"
  RC=$?
  append_output --data "${xml_exe} sel -t -c \"${transformer}(${xpath})\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"

  [ -n "${output}" ] && printf "%s\n" "${output}"
  return "${RC}"
}

xml_check_file()
{
  __debug $@

  typeset xmlfile=
  typeset errorcode="${FAIL}"
  
  OPTIND=1
  while getoptex "x: xmlfile: e: errorcode:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'errorcode' ) errorcode="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ]
  then
    xml_fail --message "No XML file provided" --errorcode "${errorcode}"
    return $?
  elif [ ! -f "${xmlfile}" ]
  then
    xml_fail --message "Unable to find necessary XML file : <${xmlfile}>" --errorcode "${errorcode}"
    return $?
  fi
  
  return "${PASS}"
}

xml_count_entries()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset numitems=0
  
  OPTIND=1
  while getoptex "p: xpath: x. xmlfile." "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  if [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ]
  then
    printf "%d\n" "${numitems}"
    return "${FAIL}"
  fi

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    printf "%d\n" "${numitems}"
    return "${RC}"
  fi
  
  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    xml_fail --message "No xpath provided"
    printf "%d\n" "${numitems}"
    return "${FAIL}"
  fi

  typeset details="$*"
  
  typeset output="$( __xml_transform --xmlfile "${xmlfile}" --xpath "${xpath}" --transform 'count' $@ )"
  RC=$?
  if [ -n "${output}" ]
  then
    printf "%d\n" "${output}"
  else
    printf "%d\n" "${numitems}"
  fi
  return "${RC}"
}

xml_delete_entry()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset value=
  typeset overwrite=
  typeset msg='Unable to find requested element'
  
  OPTIND=1
  while getoptex "p: xpath: x. xmlfile. o overwrite" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    'o'|'overwrite' ) overwrite='-L';;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    xml_fail --message "No xpath provided"
    return "${FAIL}"
  fi

  typeset details="$*"
  
  typeset output=
  if [ -z "${overwrite}" ]
  then
    output="$( ${xml_exe} edit ${overwrite} -d "${xpath}" ${details} \"${xmlfile}\" 2>/dev/null )"
    RC=$?
    if [ "$( is_empty --str "${output}" )" -eq "${YES}" ] || [ "${RC}" -gt "${PASS}" ]
    then
      xml_fail --message "${xpath} : ${msg}"
      return "${FAIL}"
    fi
  
    typeset outfile="$( make_output_file --channel 'XML_EDIT' )"
    [ -n "${outfile}" ] && [ -f "${outfile}" ] && printf "%s\n" "${output}" > "${outfile}"
    printf "%s\n" "${outfile}"
  else
    ${xml_exe} edit ${overwrite} -d "${xpath}" ${details} "${xmlfile}"
  fi
  
  return "${PASS}"
}

xml_edit_entry()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"


  typeset xmlfile=
  typeset xpath=
  typeset value=
  typeset overwrite=
  typeset msg='Unable to find requested element'
  
  OPTIND=1
  while getoptex "p: xpath: v: value: x. xmlfile. o overwrite" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    'v'|'value'     ) value="${OPTARG}";;
    'o'|'overwrite' ) overwrite='-L';;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    xml_fail --message "No xpath provided"
    return "${FAIL}"
  fi

  typeset details="$*"
  
  typeset output=
  if [ -z "${overwrite}" ]
  then
    output="$( ${xml_exe} edit ${overwrite} -u "${xpath}" -v "${value}" ${details} \"${xmlfile}\" 2>/dev/null )"
    RC=$?
    if [ "$( is_empty --str "${output}" )" -eq "${YES}" ] || [ "${RC}" -gt "${PASS}" ]
    then
      xml_fail --message "${xpath} : ${msg}"
      return "${NO}"
    fi
  
    typeset outfile="$( make_output_file --channel 'XML_EDIT' )"
    [ -n "${outfile}" ] && [ -f "${outfile}" ] && printf "%s\n" "${output}" > "${outfile}"
    printf "%s\n" "${outfile}"
  else
    ${xml_exe} edit ${overwrite} -u "${xpath}" -v "${value}" ${details} "${xmlfile}"
  fi
  
  return "${PASS}"
}

xml_exists()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset msg='Unable to find requested element'
  
  OPTIND=1
  while getoptex "p: xpath: m: msg: message: x. xmlfile." "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'         ) xpath="${OPTARG}";;
    'x'|'xmlfile'       ) xmlfile="${OPTARG}";;
    'm'|'msg'|'message' ) msg="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${NO}"
  
  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${NO}"
  
  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    xml_fail --message "No xpath provided"
    return "${NO}"
  fi

  typeset details="$*"
  
  typeset output=
  output="$( ${xml_exe} sel -t -m "${xpath}" -v '.' ${details} "${xmlfile}" 2>/dev/null )"
  RC=$?
  append_output --data "${xml_exe} sel -t -m \"${xpath}\" -v \".\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"

  if [ "$( is_empty --str "${output}" )" -eq "${YES}" ]
  then
    xml_fail --message "${xpath} : ${msg}"
    return "${NO}"
  fi
  return "${YES}"
}

xml_fail()
{
  __debug $@

  typeset msg=
  typeset errorcode="${FAIL}"
  
  OPTIND=1
  while getoptex "m: msg: message: e: errorcode:" "$@"
  do
    case "${OPTOPT}" in
    'e'|'errorcode'     ) errorcode="${OPTARG}";;
    'm'|'msg'|'message' ) msg="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${msg}" )" -eq "${NO}" ] && __xml_suppression "${msg}"

  return "${errorcode}"
}

xml_generate_new_file()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset rootnode_id=
  typeset subnodes=
  typeset preserve="${NO}"

  OPTIND=1
  while getoptex "x. xmlfile. r: rootnode-id: s: subnode: p preserve" "$@"
  do
    case "${OPTOPT}" in
    'r'|'rootnode-id'  ) rootnode_id="${OPTARG}";;
    'x'|'xmlfile'      ) xmlfile="${OPTARG}";;
    's'|'subnode'      ) subnodes+=" ${OPTARG}";;
    'p'|'preserve'     ) preserve="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${rootnode_id}" )" -eq "${YES}" ] && return "${FAIL}"

  \touch "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  
  ###
  ### This needs to be looked at again : TODO
  ###
  if [ "${preserve}" -eq "${NO}" ]
  then
    printf "%s\n" "$( __xml_generate_header )" > "${xmlfile}"
    printf "%s\n" "<${rootnode_id}>" >> "${xmlfile}"
    printf "%s\n" "</${rootnode_id}>" >> "${xmlfile}"
  else
    printf "%s\n" "$( __xml_generate_header )" > "${xmlfile}.tmp"
   
    typeset OLDIFS="${IFS}"
    IFS='/'
    
    typeset xmldepth=
    typeset sn=
    for sn in ${rootnode_id}
    do
      [ -z "${sn}" ] && continue
      xmldepth="${sn} ${xmldepth}"
      printf "%s\n" "<${sn}>" >> "${xmlfile}.tmp"
    done
    IFS="${OLDIFS}"
    
    \cat "${xmlfile}" >> "${xmlfile}.tmp"
    for sn in ${xmldepth}
    do
      printf "%s\n" "</${sn}>" >> "${xmlfile}.tmp"
    done
    
    ${xml_exe} fo "${xmlfile}.tmp" > "${xmlfile}"
    \rm -f "${xmlfile}.tmp"
  fi
  
  #typeset sn
  #for sn in ${subnodes}
  #do
  #  typeset OLDIFS="${IFS}"
  #  IFS='/'
    
  #  typeset prevsbn=
  #  typeset sbn
  #  for sbn in ${sn}
  #  do
      ###
      ### Need to put back the IFS setting to make sure xmlstarlet will work properly
      ###
  #    unset IFS
  #    ${xml_exe} ed --inplace --subnode "/${rootnode_id}${prevsbn}" --type elem -n "${sbn}" --value '' "${xmlfile}"
  #    IFS='/'
  #    append_output --data "${xml_exe} ed --inplace --subnode \"/${rootnode_id}${prevsbn}\" --type elem -n \"${sbn}\" --value \"\" \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel XML
  #    prevsbn+="/${sbn}"
  #  done
  #  unset IFS
  #done
  
  return "${PASS}"
}

xml_get_attribute()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset field=
  typeset format="%q"

  OPTIND=1
  while getoptex "x. xmlfile. p: xpath: a: attr: attribute: format:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'             ) xpath="${OPTARG}";;
    'x'|'xmlfile'           ) xmlfile="${OPTARG}";;
    'a'|'attr'|'attribute'  ) field="${OPTARG}";;
        'format'            ) format="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${field}" )" -eq "${YES}" ] && return "${FAIL}"

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset output="$( xml_get_single_entry --xmlfile "${xmlfile}" --xpath "${xpath}" --field "@${field}" --format "${format}" $@ )"
  typeset RC=$?
  [ -n "${output}" ] && print_plain --format "${format}" --message "${output}"

  return "${RC}"
}

xml_get_channel()
{
  __debug $@
  printf "%s\n" "${__XML_TRACING_CHANNEL}"
  return "${PASS}"
}

xml_get_file()
{
  [ -n "${__STD_XMLFILE}" ] && print_plain --message "${__STD_XMLFILE}"
  return "${PASS}"
}

xml_get_matching_entry()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset match=
  typeset field=
  typeset format="%q"
  typeset prefix=

  OPTIND=1
  while getoptex "x. xmlfile. p: xpath: m: match: f: field: format: prefix:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'    ) xpath="${OPTARG}";;
    'x'|'xmlfile'  ) xmlfile="${OPTARG}";;
    'm'|'match'    ) match="${OPTARG}";;
    'f'|'field'    ) field="${OPTARG}";;
        'format'   ) format="${OPTARG}";;
        'prefix'   ) prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${field}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${match}" )" -eq "${YES}" ] && return "${FAIL}"

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
   
  typeset details="$*"
  typeset output="$( ${xml_exe} sel -t -m "${xpath}[@${match}]" -v "${field}" ${details} "${xmlfile}" )"
  [ -n "${prefix}" ] && output="${prefix}${output}"

  [ "$( is_empty --str "${output}" )" -ne "${YES}" ] && print_plain --format "${format}" --message "${output}"
  append_output --data "${xml_exe} sel -t -m \"${xpath}[@${match}]\" -v \"${field}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"

  return "${PASS}"
}

xml_get_multi_entry()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset fields=
  typeset format="%q"
  typeset match="${YES}"
  typeset prefix=
  
  OPTIND=1
  while getoptex "x. xmlfile. p: xpath: f: field: format: no-match prefix:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'    ) xpath="${OPTARG}";;
    'x'|'xmlfile'  ) xmlfile="${OPTARG}";;
    'f'|'field'    ) fields+=" ${OPTARG}";;
        'format'   ) format="${OPTARG}";;
        'no-match' ) match="${NO}";;
        'prefix'   ) prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${fields}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset details="$*"

  typeset output=
  typeset concat_string=
  if [ "${match}" -eq "${YES}" ]
  then
    concat_string="concat("

    typeset fldarg=
    for fldarg in ${fields}
    do
      concat_string+="${fldarg}, ' ',"
    done

    [ -n "${fields}" ] && concat_string="${concat_string%?}"
    concat_string+=')'
    output="$( ${xml_exe} sel -t -m "${xpath}" -v "${concat_string}" -n ${details} "${xmlfile}" )"
  else
    #for fldarg in ${fields}
    #do
    #  concat_string+="/${fldarg}"
    #done
    fields="$( trim "${fields}" )"
    output="$( ${xml_exe} sel -t -v "${xpath}/${fields}" -n ${details} "${xmlfile}" | \tr '\n' ' ' )"
  fi
  [ -n "${prefix}" ] && output="${prefix}${output}"
  
  [ "$( is_empty --str "${output}" )" -eq "${NO}" ] && print_plain --format "${format}" --message "${output}"
  
  if [ "${match}" -eq "${YES}" ]
  then
    append_output --data "${xml_exe} sel -t -m \"${xpath}\" -v \"${concat_string}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  else
    append_output --data "${xml_exe} sel -t -v \"${xpath}/$fields\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  fi  

  return "${PASS}"  
}

xml_get_rootnode_name()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=

  OPTIND=1
  while getoptex "x. xmlfile." "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlfile'  ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset validXML="$( xml_validate --xmlfile "${xmlfile}" )"
  [ "${validXML}" == 'NO' ] && return "${FAIL}"
  
  typeset rootnode="$( ${xml_exe} el -u "${xmlfile}" | \head -n 1 )"

  [ "$( is_empty --str "${rootnode}" )" -eq "${NO}" ] && printf "%s\n" "${rootnode}"
  return "${PASS}"
}

xml_get_single_entry()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset field=
  typeset format="%q"
  typeset prefix=
  
  OPTIND=1
  while getoptex "x. xmlfile. p: xpath: f: field: format: prefix:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'    ) xpath="${OPTARG}";;
    'x'|'xmlfile'  ) xmlfile="${OPTARG}";;
    'f'|'field'    ) field="${OPTARG}";;
        'format'   ) format="${OPTARG}";;
        'prefix'   ) prefix="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ "$( is_empty --str "${field}" )" -eq "${YES}" ]
  then
    field="$( \basename "${xpath}" )"
    xpath="$( printf "%s\n" "${xpath}" | \sed -e 's#/[^/]*$##' )"
  fi
  [ "$( is_empty --str "${field}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset details="$*"
  typeset output="$( ${xml_exe} sel -t -m "${xpath}" -v "${field}" ${details} "${xmlfile}" )"
  [ -n "${prefix}" ] && output="${prefix}${output}"

  [ "$( is_empty --str "${output}" )" -ne "${YES}" ] && print_plain --format "${format}" --message "${output}"

  append_output --data "${xml_exe} sel -t -m \"${xpath}\" -v \"${field}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  return "${PASS}"
}

xml_get_subxml()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset keep_rtnd=

  OPTIND=1
  while getoptex "x. xmlfile. p: xpath: keep-rootnode:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'          ) xpath="${OPTARG}";;
    'x'|'xmlfile'        ) xmlfile="${OPTARG}";;
        'keep-rootnode'  ) keep_rtnd="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset channel_name="$( make_next_available_channel_for_file )"
  #typeset count=0
  #typeset channel_name="${__FILEMARKER}${count}"
  #typeset already_in_use=$( find_output_file --channel "${channel_name}" )

  #while [ -n "${already_in_use}" ] || [ -f "${already_in_use}" ]
  #do
  #  count=$(( count + 1 ))
  #  channel_name="${__FILEMARKER}${count}"
  #  already_in_use=$( find_output_file --channel "${channel_name}" )
  #done

  typeset subxmlfile="$( make_output_file --channel "${channel_name}" )"
  [ "$( is_empty --str "${subxmlfile}" )" -eq "${YES}" ] && return "${FAIL}"
  
  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset details="$*"
  typeset output="$( ${xml_exe} sel -t -c "${xpath}" ${details} "${xmlfile}" > "${subxmlfile}" )"

  if [ -n "${keep_rtnd}" ]
  then
    \sed "1i <${rootnode}>" "${subxmlfile}" > "${subxmlfile}.1"
    printf "%s\n" "</${rootnode}>" >> "${subxmlfile}.1"
    ${xml_exe} fo "${subxmlfile}.1" > "${subxmlfile}"
  fi

  if [ $? -eq "${PASS}" ]
  then
    printf "%q" "${subxmlfile}"
  else
    remove_output_file --channel "${channel_name}"
  fi

  append_output --data "${xml_exe} sel -t -c \"${xpath}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  return "${PASS}"
}

xml_get_text()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  xml_get_single_entry $@
  return $?
}

xml_has_attribute()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset output="$( xml_get_attribute $@ )"
  typeset RC=$?
  
  if [ "${RC}" -eq "${PASS}" ] && [ -n "${output}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"  
}

xml_has_node()
{
  __debug $@
  
  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset node=
  
  OPTIND=1
  while getoptex "p: xpath: x. xmlfile. n: node:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    'n'|'node'      ) node="${OPTARG}";;
   esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  if [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ]
  then
    print_no
    return "${FAIL}"
  fi
  
  typeset details="$*"

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
    return "${RC}"
  fi
  
  typeset output=
  if [ "$( is_empty --str "${node}" )" -eq "${YES}" ]
  then
    output="$( ${xml_exe} sel -t -c "${xpath}" ${details} "${xmlfile}" )"
    append_output --data "${xml_exe} sel -t -c \"${xpath}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  else
    output="$( ${xml_exe} sel -t -c "${xpath}/${node}" ${details} "${xmlfile}" )"
    append_output --data "${xml_exe} sel -t -c \"${xpath}/${node}\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"
  fi  
  RC=$?
  
  if [ "${RC}" -eq "${PASS}" ] && [ "$( is_empty --str "${output}" )" -eq "${NO}" ]
  then
    print_yes
  else
    print_no
  fi
  return "${PASS}"
}

xml_merge()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile_send=
  typeset xpath=
  typeset xmlfile_rec=
  
  OPTIND=1
  while getoptex "p: xpath: xmlfile-send: xmlfile-receive:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'            ) xpath="${OPTARG}";;
        'xmlfile-send'     ) xmlfile_send="${OPTARG}";;
        'xmlfile-receive'  ) xmlfile_rec="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${xmlfile_send}" )" -eq "${YES}" ] || [ ! -f "${xmlfile_send}" ]
  then
     return "${FAIL}"
  fi
  
  if [ "$( is_empty --str "${xmlfile_rec}" )" -eq "${YES}" ] || [ ! -f "${xmlfile_rec}" ]
  then
    return "${FAIL}"
  fi
  [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset output="$( ${xml_exe} sel -t -m "${xpath}" -c "document(${xmlfile_rec})" "${xmlfile_send}" )"
  return "${PASS}"
}

xml_node_processor()
{
  typeset RC="${PASS}"
  typeset xmlfile=
  typeset processor_func=
  typeset nodetype=

  OPTIND=1
  while getoptex "x: xmlfile: p: processor-func: n: node-type:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlfile'         ) xmlfile="${OPTARG}";;
    'p'|'processor-func'  ) processor_func="${OPTARG}";;
    'n'|'node-type'       ) nodetype="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"

  [ "$( is_empty --str "${nodetype}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( is_empty --str "${processor_func}" )" -eq "${YES}" ] && return "${PASS}"

  typeset rootnode="$( xml_get_rootnode_name --xmlfile "${xmlfile}" )"
  [ "$( is_empty --str "${rootnode}" )" -eq "${YES}" ] && return "${FAIL}"

  [ "$( xml_has_node --xpath "/${rootnode}" --node "${nodetype}" )" -eq "${NO}" ] && return "${FAIL}"
  typeset subfile="$( xml_get_subxml --xpath "/${rootnode}/${nodetype}" )"
  RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    eval "${processor_func} \"${subfile}\""
    RC=$?
    \rm -f "${subfile}"
  fi
  return "${RC}"
}

xml_select_entry()
{
  __debug $@

  [ -z "${xml_exe}" ] && return "${FAIL}"

  typeset xmlfile=
  typeset xpath=
  typeset entry_id=0
  
  OPTIND=1
  while getoptex "p: xpath: x. xmlfile. i: id:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'xpath'     ) xpath="${OPTARG}";;
    'x'|'xmlfile'   ) xmlfile="${OPTARG}";;
    'i'|'id'        ) entry_id="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && xmlfile="${__STD_XMLFILE}"
  [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ "$( is_numeric_data --data "${entry_id}" )" -eq "${NO}" ] || [ "${entry_id}" -lt 1 ]
  then
    return "${FAIL}"
  fi

  xml_check_file --xmlfile "${xmlfile}"
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"
  
  if [ "$( is_empty --str "${xpath}" )" -eq "${YES}" ]
  then
    xml_fail --message "No xpath provided"
    return "${FAIL}"
  fi

  typeset num_matching_items="$( xml_count_entries --xmlfile "${xmlfile}" --xpath "${xpath}" )"
  [ "${entry_id}" -gt "${num_matching_items}" ] && return "${FAIL}"
  
  typeset details="$*"
  
  typeset output="$( ${xml_exe} sel -t -c "${xpath}[${entry_id}]" ${details} "${xmlfile}" )"
  RC=$?
  append_output --data "${xml_exe} sel -t -c \"${xpath}[${entry_id}]\" ${details} \"${xmlfile}\" -- {RC = ${RC}} -- '${output}'" --channel "${__XML_TRACING_CHANNEL}"

  if [ "${RC}" -ne "${PASS}" ] || [ "$( is_empty --str "${output}" )" -eq "${YES}" ]
  then
    xml_fail --message "${xpath} : ${msg}"
    return "${FAIL}"
  fi
 
  printf "%s\n" "${output}"
  return "${PASS}"
}

xml_set_file()
{
  __debug $@
  typeset xmlfile

  OPTIND=1
  while getoptex "x: xmlfile:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlfile' ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${xmlfile}" )" -eq "${NO}" ] && [ -f "${xmlfile}" ]
  then
    __STD_XMLFILE="${xmlfile}"
    return "${PASS}"
  fi
  return "${FAIL}"
}

xml_set_output_file()
{
  __debug $@

  typeset xmlout=

  OPTIND=1
  while getoptex "x: xmlout:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlout' ) xmlout="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  __XML_TRACING_FILE="${xmlout}"
  associate_file_to_channel --channel "${__XML_TRACING_CHANNEL}" --file "${__XML_TRACING_FILE}" --ignore-file-existence --persist
  return $?
}

xml_set_output_channel()
{
  __debug $@

  typeset xmlchannel=

  OPTIND=1
  while getoptex "x: xmlchannel:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlchannel' ) xmlchannel="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${xmlchannel}" ] && return "${FAIL}"
  __XML_TRACING_CHANNEL="${xmlchannel}"
  return "${PASS}"
}

xml_unset_file()
{
  __STD_XMLFILE=
  return "${PASS}"
}

xml_validate()
{
  __debug $@

  if [ -z "${xml_exe}" ]
  then
    print_no
    return "${FAIL}"
  fi

  typeset xmlfile

  OPTIND=1
  while getoptex "x: xmlfile:" "$@"
  do
    case "${OPTOPT}" in
    'x'|'xmlfile' ) xmlfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${xmlfile}" )" -eq "${YES}" ] || [ ! -f "${xmlfile}" ]
  then
    print_no
    return "${FAIL}"
  fi

  ${xml_exe} val "${xmlfile}" > /dev/null 2>&1
  typeset RC=$?
  append_output --data "${xml_exe} val \"${xmlfile}\" -- {RC = ${RC}}" --channel "${__XML_TRACING_CHANNEL}"
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_no
  else
    print_yes
  fi
  return "${PASS}"
}

# ---------------------------------------------------------------------------
if [ -z "${__XML_FAILURE_SUPPRESSION}" ]
then
  __XML_FAILURE_SUPPRESSION=0
  xml_exe=
fi

xmlstarlet_exe_found=0
use_python_parser_for_xml=0

\which 'xmlstarlet' >/dev/null 2>&1
if [ $? -ne 0 ]
then
  \which 'python' > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    printf "[WARN     ] %s\n" "Unable to utilize xmlmgt.sh since << xmlstarlet|python >> is NOT available from the commandline!" "Please include ${SLCF_SHELL_TOP}/resources/<OSTYPE> in your search path..."
    printf "\n"
    SLCF_LIBRARY_ISSUE=1
  else
    xml_exe="$( \which 'python' ) -c 'from lxml.etree import parse; from sys import stdin; print '\n'.join(parse(stdin).xpath"
    use_python_parser_for_xml=1
  fi
else
  xml_exe=$( \which 'xmlstarlet' )
  xmlstarlet_exe_found=1
fi

echo "Checking ---- ${use_python_parser_for_xml} ---- ${xmlstarlet_exe_found}" >> /tmp/.xyz
if [ "${use_python_parser_for_xml}" -eq 1 ] || [ "${xmlstarlet_exe_found}" -eq 1 ]
then
  type "__initialize" 2>/dev/null | \grep -q 'is a function'
  
  # shellcheck source=/dev/null
  [ $? -ne 0 ] && . "${SLCF_SHELL_TOP}/lib/base_logging.sh"

  __initialize_xmlmgt
  [ $? -eq 0 ] && __prepared_xmlmgt
fi
