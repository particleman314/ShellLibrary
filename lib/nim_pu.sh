###############################################################################
# Copyright (c) 2016.  All rights reserved. 
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
# Author           : Mike Klusman
# Software Package : Shell Automated Testing -- UIM Configuration
# Application      : Support Functionality
# Language         : Bourne Shell
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __condense_line_pu_output
#    __determine_maximum_pu_output_depth
#    __extract_matching_lines
#    __extract_matching_sections
#    __find_end_of_pu_section
#    __find_key_at_depth
#    __find_pds_integer_names
#    __find_pds_string_names
#    __find_pds_structures
#    __find_pds_table_of_table_names
#    __find_pds_table_names
#    __find_pu_section_by_depth
#    __get_indentation_depth_from_line
#    __get_pds_content
#    __is_any_matching_section
#    __proper_pds_type
#    __remove_pu_header
#    __sort_line_groups
#    __valid_line_group
#    build_cmd_outputfile
#    extract_from_pu_output
#    extract_section
#    get_pds_key
#    get_pds_size
#    get_pds_type
#    get_pds_value
#    get_pu_addon_options
#    run_pu_command
#
###############################################################################

if [ -z "${__NIM_PU_ELEMENT_CONTINUATION}" ]
then
  __NIM_PU_ELEMENT_CONTINUATION='\!'
  __PU_HEADER_LINE='======================================================'
  __KNOWN_PDS_TYPES='PDS_I PDS_PCH PDS_PDS PDS_PPDS'
  __PU_RETRIES=3          ### maximum number of tries
  __PU_RETRY_INTERVAL=15  ### Second between retries
fi

__condense_line_pu_output()
{
  __debug $@

  typeset data="$1"
  [ -z "${data}" ] && return "${FAIL}"

  data=$( printf "%s\n" "${data}" | \sed -e "s#${__NIM_PU_ELEMENT_CONTINUATION}# #g" )
  __unix_prefix_trim "${data}" | \tr -s ' '
  return "${PASS}"
}

__determine_maximum_pu_output_depth()
{
  __debug $@

  typeset fn="$1"

  if [ -z "${fn}" ] || [ ! -f "${fn}" ]
  then
    printf "%d\n" 0
    return "${FAIL}"
  fi

  printf "%d\n" $( \awk '{ match($0, /^ */); printf("%d\n",RLENGTH) }' "${fn}" | \sort -n | \uniq | \tail -1 )
  return "${PASS}"
}

__extract_matching_lines()
{
  __debug $@

  typeset fn="$1"
  shift

  [ -z "${fn}" ] || [ ! -f "${fn}" ] && return "${FAIL}"

  if [ $# -lt 1 ]
  then
    printf "%s\n" "${fn}"
    return "${FAIL}"
  fi

  typeset sorted_groups=$( __sort_line_groups $@ )
  typeset tmpfile=$( make_temp_file )
  typeset lg
  for lg in ${sorted_groups}
  do
    typeset sectionfile=$( make_temp_file )
    if [ ! -f "${sectionfile}" ]
    then
      printf "%s\n" "${fn}"
      return "${FAIL}"
    fi
    typeset bgnln=$( get_element --data "${lg}" --id 1 --separator ':' )
    typeset endln=$( get_element --data "${lg}" --id 2 --separator ':' )
    copy_file_segment --filename "${fn}" --beginline ${bgnln} --endline ${endln} --outputfile "${sectionfile}"
    \cat "${sectionfile}" >> "${tmpfile}"
    [ -f "${sectionfile}" ] && \rm -f "${sectionfile}"
  done

  if [ $( __get_char_count "${tmpfile}" ) -eq 0 ]
  then
    printf "%s\n" "${fn}"
  else
    printf "%s\n" "${tmpfile}"
  fi
  return "${PASS}"
}

__extract_matching_sections()
{
  typeset fn="$1"
  shift

  [ -z "${fn}" ] || [ ! -f "${fn}" ] && return "${FAIL}"

  [ $# -lt 1 ] && return "${FAIL}"

  typeset sorted_groups=$( __sort_line_groups $@ )

  typeset updated_line_groups
  typeset lg
  for lg in ${sorted_groups}
  do
    typeset bgnln=$( get_element --data "${lg}" --id 1 --separator ':' )
    typeset endln=$( get_element --data "${lg}" --id 2 --separator ':' )

    if [ "${bgnln}" -eq 1 ]
    then
      updated_line_groups="${updated_line_groups} ${bgnln}:${endln}"
      continue
    fi

    typeset top_section_found="${NO}"
    while [ "${top_section_found}" -eq "${NO}" ] && [ "${bgnln}" -gt 1 ]
    do
      if [ "${bgnln}" -gt 1 ]
      then
        bgnln=$(( bgnln - 1 ))
      else
        updated_line_groups="${updated_line_groups} ${bgnln}:${endln}"
        break
      fi

      typeset test_line=$( copy_file_segment --filename "${fn}" --beginline "${bgnln}" --endline "${bgnln}" )

      if [ "${test_line}" == "${__PU_HEADER_LINE}" ]
      then
        top_section_found="${YES}"
        bgnln=$(( bgnln + 1 ))
        updated_line_groups="${updated_line_groups} ${bgnln}:${endln}"
        continue
      fi

      typeset entry_type=$( get_pds_type --data "${test_line}" )
      if [ "${entry_type}" == 'PDS_PDS' ]
      then
        top_section_found="${YES}"
        updated_line_groups="${updated_line_groups} ${bgnln}:${endln}"
        continue
      fi
    done
  done

  updated_line_groups=$( __sort_line_groups ${updated_line_groups} )

  __extract_matching_lines "${fn}" ${updated_line_groups}
  return "${PASS}"
}

__find_end_of_pu_section()
{
  __debug $@

  typeset fn="$1"
  typeset stpt="$2"
  typeset section_only="${3:-${NO}}"

  if [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ -z "${stpt}" ] || [ $( is_numeric_data --data "${stpt}" ) -eq "${NO}" ]
  then
    printf "%d\n" -1
    return "${FAIL}"
  fi

  typeset data=$( copy_file_segment --filename "${fn}" --beginline "${stpt}" --endline "${stpt}" )
  typeset data_pdstype=
  [ "${section_only}" -eq "${YES}" ] && data_pdstype=$( get_pds_type --data "${data}" )

  typeset indent_size=$( printf "%s\n" "${data}" | \awk '{ match($0, /^ */); printf("%d\n",RLENGTH) }' )
  typeset szfn=$( __get_line_count "${fn}" )

  if [ "${stpt}" -ge "${szfn}" ]
  then
    printf "%d\n" "${stpt}"
    return "${PASS}"
  fi

  typeset endpt="${stpt}"
  typeset tmp_endpt=
  typeset indent_results=$( copy_file_segment --filename "${fn}" --beginline "$(( stpt + 1 ))" --endline "${szfn}" | \awk '{ match($0, /^ */); printf("%d:%d\n",RLENGTH,NR) }' )
  typeset ir=
  for ir in ${indent_results}
  do
    typeset spacing=$( get_element --data "${ir}" --id 1 --separator ':' )
    typeset recid=$( get_element --data "${ir}" --id 2 --separator ':' )
    if [ "${spacing}" -lt "${indent_size}" ]
    then
      if [ -z "${tmp_endpt}" ]
      then
        endpt=$(( stpt + recid ))
      else
        endpt="${tmp_endpt}"
      fi
      tmp_endpt=
      break
    elif [ "${spacing}" -eq "${indent_size}" ]
    then
      tmp_endpt=$(( stpt + recid ))
      if [ "${section_only}" -eq "${YES}" ]
      then
        tmp_endpt=$(( tmp_endpt - 1 ))
        break
      fi
    else
      #[ -n "${tmp_endpt}" ] && tmp_endpt=$(( stpt + recid ))
      tmp_endpt=$(( stpt + recid ))
    fi
  done

  [ -n "${tmp_endpt}" ] && endpt="${tmp_endpt}"
  printf "%d\n" "${endpt}"
  return "${PASS}"
}

__find_pds_integer_names()
{
  __find_pds_structures "$1" 'PDS_I'
}

__find_key_at_depth()
{
  typeset fn="$1"
  typeset key="$2"
  typeset depth="${3:-0}"
  typeset nth_match="${4:-0}"

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ "${depth}" -lt 0 ] || [ -z "${key}" ] || [ "${nth_match}" -lt 0 ] && return "${FAIL}"

  typeset chid="SUB_PDS_$( __today_as_seconds )"

  if [ "${nth_match}" -gt 0 ]
  then
    typeset tmpfile=$( make_temp_file )
    register_tmpfile --filename "${tmpfile}" --channel "${chid}"
    \grep "${key}" "${fn}" >> "${tmpfile}"

    typeset nummatches=$( __get_line_count "${tmpfile}" )
    if [ "${nummatches}" -gt "${nth_match}" ]
    then
      \cat "${tmpfile}" | \head -${nth_match} | \tail -1
    elif [ "${nummatches}" -eq "${nth_match}" ]
    then
      \cat "${tmpfile}" | \tail -1
    fi

    discard --channel "${chid}"
    return "${PASS}"
  else
    typeset tmpfile=$( __find_pu_section_by_depth "${fn}" "${depth}" )
    if [ -f "${tmpfile}" ]
    then
      __condense_line_pu_output "$( \grep "^${key} " "${tmpfile}" )"
      \rm -f "${tmpfile}"
      return "${PASS}"
    fi

    #typeset matching_line_numbers=$( __find_pu_section_by_depth "${fn}" "${depth}" )
    #echo "MLN : ${matching_line_numbers}" >> /tmp/xyz
    #pause
    #typeset groups=$( __group_line_counts "${matching_line_numbers}" )

    #[ -z "${groups}" ] && return "${FAIL}"

    #typeset spacer=$( get_repeated_char_sequence --count "${depth}" | sed -e "s#${__STD_REPEAT_CHAR}# #g" )

    #typeset grp
    #typeset count=1
    #for grp in ${groups}
    #do
    #  typeset s=$( get_element --data "${grp}" --id 1 --separator ':' )
    #  typeset e=$( get_element --data "${grp}" --id 2 --separator ':' )

      # Select out the lines defined and then search each one for the request key
      #typeset match=$( sed -n "${s},${e}q;d" "${fn}" -e "s#${spacer}##" | grep "^${key}" )
      #if [ -n "${match}" ] && [ "${count}" -eq "${nth_match}" ]
      #then
        #printf "%s\n" "${match}" 
        #return "${PASS}"
      #fi
    #done
  fi
  return "${FAIL}"
}

__find_pds_string_names()
{
  __find_pds_structures "$1" 'PDS_PCH'
}

__find_pds_structures()
{
  typeset fn="$1"
  typeset structtype="$2"

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ -z "${structtype}" ] && return "${FAIL}"

  typeset results=$( \awk '{ match($0, /^ */); printf("%d:%s\n",RLENGTH,$0) }' "${fn}" | \grep '^0:' | \grep "${structtype}" | \cut -f 2 -d ':' )
  typeset r=
  typeset new_r=
  typeset names=

  typeset OLDIFS=${IFS}
  IFS="$(printf '\n+')"
  for r in ${results}
  do
    [ -z "${r}" ] && continue
    r=$( printf "%s\n" "${r}" | \sed -e "s# #${__NIM_PU_ELEMENT_CONTINUATION}#g" )
    new_r="${new_r} ${r}"
  done
  IFS=${OLDIFS}

  for r in ${new_r}
  do
    [ -z "${r}" ] && continue
    typeset reduced=$( get_pds_key --data "${r}" )
    names="${names} ${reduced}"
  done

  [ -n "${names}" ] && printf "%s\n" "$( trim "${names}" )"
  return "${PASS}"
}

__find_pds_table_of_table_names()
{
  __find_pds_structures "$1" 'PDS_PPDS'
  return $?
}

__find_pds_table_names()
{
  __find_pds_structures "$1" 'PDS_PDS'
  return $?
}

__find_pu_section_by_depth()
{
  typeset fn="$1"
  typeset subsection_depth="$2"

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ -z "${subsection_depth}" ] || [ "${subsection_depth}" -lt 0 ] && return "${FAIL}"

  fn=$( __remove_pu_header "${fn}" )
  __add_junk_file "${fn}"

  typeset results=$( \awk '{ match($0, /^ */); printf("%d:%d\n",RLENGTH,NR) }' "${fn}" )
  typeset sz
  typeset line_groups

  for sz in ${results}
  do
    typeset line_indent=$( get_element --data "${sz}" --id 1 --separator ':' )
    typeset recid=$( get_element --data "${sz}" --id 2 --separator ':' )
    [ "${line_indent}" -ge "${subsection_depth}" ] && line_groups="${line_groups} ${recid}"
  done

  if [ -n "${line_groups}" ]
  then
    line_groups=$( __group_line_counts ${line_groups} )
    __extract_matching_sections "${fn}" ${line_groups}
  fi

  __cleanup_junk_files
  return "${PASS}"
}

__get_indentation_depth_from_line()
{
  typeset fn="$1"
  if [ -z "${fn}" ]
  then
    printf "%d\n" -1
    return "${FAIL}"
  fi

  if [ ! -f "${fn}" ]
  then
    printf "%s\n" "${fn}" | \awk '{ match($0, /^ */); printf("%d\n",RLENGTH) }'
  else
    if [ -z "$2" ] || [ $( is_numeric_data --data "$2" ) -eq "${NO}" ]
    then
      printf "%d\n" -1
      return "${FAIL}"
    fi

    typeset lnid="$2"
    typeset maxlineid=$( __get_line_count "${fn}" )
    if [ "${lnid}" -gt "${maxlineid}" ]
    then
      printf "%d\n" -1
      return "${FAIL}"
    fi
    copy_file_segment --filename "${fn}" --beginline "${lnid}" --endline "${lnid}" | \awk '{ match($0, /^ */); printf("%d\n",RLENGTH) }'
  fi
  return "${PASS}"
}

__get_pds_content()
{
  typeset input=
  typeset fld_id=

  OPTIND=1
  while getoptex "d: data: f: field:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'  ) input="${OPTARG}";;
    'f'|'field' ) fld_id="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${input}" ] && return "${FAIL}"
  printf "%s\n" $( __condense_line_pu_output "${input}" | \cut -f "${fld_id}" -d ' ' )
  return "${PASS}"
}

__has_section()
{
  typeset fn="$1"
  typeset sectname="$2"
  typeset answer="${NO}"

  if [ -n "${fn}" ] && [ -f "${fn}" ] && [ -n "${sectname}" ]
  then
    typeset sections=$( __find_pds_table_names "${fn}" 'PDS_PDS' )
    typeset super_sections=$( __find_pds_table_of_table_names "${fn}" 'PDS_PPDS' )

    typeset s=
    for s in ${sections} ${super_sections}
    do
      if [ "${s}" == "${sectname}" ]
      then
        answer="${YES}"
        break
      fi
    done
  fi
  printf "%d\n" "${answer}"
  return "${PASS}"
}

__initialize_nim_pu()
{
  if [ -z "${SLCF_SHELL_TOP}" ]
  then
    SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
    SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
    SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"
  fi

  __load __initialize_filemgt "${SLCF_SHELL_TOP}/lib/filemgt.sh"

  __initialize "__initialize_nim_pu"
}

__is_any_matching_section()
{
  typeset input="$1"
  if [ -z "$1" ]
  then
    printf "%d\n" 0
    return "${FAIL}"
  fi

  [ "$( printf "%s\n" "${input}" | \sed -e 's#^\$##' )" != "${input}" ] && printf "%d\n" 1 || printf "%d\n" 0
  return "${PASS}"
}

__prepared_nim_pu()
{
  __prepared "__prepared_nim_pu"
}

__proper_pds_type()
{
  typeset input="$1"
  shift

  [ -z "${input}" ] && return "${FAIL}"

  typeset matched="${NO}"
  typeset pt
  for pt in ${__KNOWN_PDS_TYPES}
  do
    if [ "${input}" == "${pt}" ]
    then
      matched="${YES}"
      break
    fi
  done

  if [ "${matched}" -eq "${YES}" ]
  then
    printf "%s\n" "${input}"
  else
    return "${FAIL}"
  fi
  return "${PASS}"
}

__reduce_indentation()
{
   __debug $@

  typeset fn="$1"
  typeset indentsize="${2:-0}"

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ "${indentsize}" -le 0 ] && return "${FAIL}"

  typeset tmpfile=$( make_temp_file )
  [ -z "${tmpfile}" ] || [ ! -f "${tmpfile}" ] && return "${FAIL}"

  \sed -e "s# \{0,${indentsize}\}##" "${fn}" > "${tmpfile}"
  \mv -f "${tmpfile}" "${fn}"
  return "${PASS}"
}

__remove_pu_header()
{
  typeset fn="$1"

  [ -z "${fn}" ] || [ ! -f "${fn}" ] && return "${FAIL}"

  typeset matched_line_id=$( \grep -n "${__PU_HEADER_LINE}" "${fn}" | \tail -1 | \cut -f 1 -d ':' )
  if [ -z "${matched_line_id}" ]
  then
    printf "%s\n" "${fn}"
    return "${PASS}"
  fi
  typeset start_line=$(( matched_line_id + 1 ))

  typeset tmpfile=$( make_temp_file )
  copy_file_segment --filename "${fn}" --beginline "${start_line}" --endline "$( __get_line_count "${fn}" )" --outputfile "${tmpfile}"
  typeset RC=$?

  printf "%s\n" "${tmpfile}"
  return "${RC}"
}

__set_pu_retries()
{
  typeset max_retries="$1"
  [ $( is_numeric_data --data "${max_retries}" ) -eq "${NO}" ] && return "${FAIL}"
  
  max_retries=$( __range_limit ${max_retries} 0 10 )
  [ "${max_retries}" -gt 0 ] __PU_RETRIES="${max_retries}"
  return "${PASS}"
}

__sort_line_groups()
{
  [ $# -lt 1 ] && return "${PASS}"

  typeset lg
  typeset last_begin_line_seen
  typeset last_end_line_seen
  typeset count=1

  typeset sorted_groups
  typeset line_sort_order=$( printf "%s\n" $@ | \sort -n )

  for lg in ${line_sort_order}
  do
    [ $( __valid_line_group "${lg}" ) -eq "${NO}" ] && continue
    typeset current_group_first_line=$( get_element --data "${lg}" --id 1 --separator ':' )
    typeset current_group_last_line=$( get_element --data "${lg}" --id 2 --separator ':' )
    if [ "${count}" -eq 1 ]
    then
      last_begin_line_seen="${current_group_first_line}"
      last_end_line_seen="${current_group_last_line}"
      count=$(( count + 1 ))
      continue
    else
      if [ "${current_group_first_line}" -gt "${last_end_line_seen}" ]
      then
        sorted_groups="${sorted_groups} ${last_begin_line_seen}:${last_end_line_seen}"
        last_begin_line_seen="${current_group_first_line}"
        last_end_line_seen="${current_group_last_line}"
      else
        last_end_line_seen="${current_group_last_line}"
      fi
    fi
  done

  [ -n "${last_begin_line_seen}" ] && [ -n "${last_end_line_seen}" ] && sorted_groups="${sorted_groups} ${last_begin_line_seen}:${last_end_line_seen}"
  printf "%s\n" "$( trim "${sorted_groups}" )"
  return "${PASS}"
}

__valid_line_group()
{
  if [ $# -lt 1 ]
  then
    printf "%d\n" "${NO}"
  else
    typeset piece_count=$( __get_word_count $( printf "%s\n" "$1" | \sed -e 's#:# #g' ) )
    if [ "${piece_count}" -ne 2 ]
    then
      print_no
    else
      print_yes
    fi
  fi
  return "${PASS}"
}

build_callback_outputfile()
{
  typeset probe='controller'
  typeset callback=

  OPTIND=1
  while getoptex "p: probe-id: c: callback:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'probe-id' ) probe="${OPTARG}";;
    'c'|'callback' ) callback="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ $( is_empty --str "${callback}" ) -eq "${YES}" ]
  then
    printf "%s\n" "${probe}.unknown_cmd.data"
  else
    printf "%s\n" "${probe}.${callback}.data"
  fi
  return "${PASS}"
}

# File leak somewhere which needs to be found
extract_from_pu_output()
{
  typeset fn=
  typeset key=
  typeset pdsmatch=
  typeset disregard_pds="${NO}"

  OPTIND=1
  while getoptex "f: filename: k: key: p: pdstype:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename' ) fn="${OPTARG}";;
    'k'|'key'      ) key="${OPTARG}";;
    'p'|'pdstype'  ) pdsmatch=$( __proper_pds_type "${OPTARG}" );;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ -z "${key}" ] && return "${FAIL}"
  [ -z "${pdstype}" ] && disregard_pds="${YES}"

  typeset numlevels=$( __get_word_count "$( printf "%s\n" "${key}" | \sed -e 's#/# #g' )" )
  [ -z "${numlevels}" ] && return "${FAIL}"
  numlevels=$(( numlevels - 1 )) # Zero based counting

  typeset matching_section=
  typeset result=
  if [ "${numlevels}" -eq 0 ]
  then
    if [ $( __has_section "${fn}" "${key}" ) -eq "${YES}" ]
    then
      typeset tmpfile=$( extract_section --filename "${fn}" --key "${key}" )
      if [ -f "${tmpfile}" ]
      then      
        result=$( \cat "${tmpfile}" )
        \rm -f "${tmpfile}"
      fi
    else
      result=$( __find_key_at_depth "${fn}" "${key}" 0 )
    fi
  else
    typeset tmpfile=$( make_temp_file )
    typeset chid="EXTRACT_PU_$( __today_as_seconds )"

    register_tmpfile --filename "${tmpfile}" --channel "${chid}"
    if [ -z "${tmpfile}" ] || [ ! -f "${tmpfile}" ]
    then
      discard --channel "${chid}"
      return "${FAIL}"
    fi

    \cp -f "${fn}" "${tmpfile}"

    typeset depth=
    typeset range=$( __get_sequence 0 ${numlevels} )
    for depth in ${range}
    do
      typeset subkey=$( get_element --data "${key}" --id "$(( depth + 1 ))" --separator '/' )
 
      if [ "${numlevels}" -ge 1 ]
      then
        #typeset newtmpfile=$( make_temp_file )
        #[ -z "${newtmpfile}" ] || [ ! -f "${newtmpfile}" ] && return "${FAIL}"

        typeset pdstype='PDS_PPDS'
        [ "${numlevels}" -eq 1 ] && pdstype='PDS_PDS'

        typeset newtmpfile=$( extract_section --filename "${tmpfile}" --key "${subkey}" )
        if [ -f "${newtmpfile}" ]
        then
          \mv -f "${newtmpfile}" "${tmpfile}"
        else
          matching_section="${NO}"
          break
        fi
      else
        if [ $( __has_section "${tmpfile}" "${subkey}" ) -eq "${YES}" ]
        then
          tmpfile=$( extract_section --filename "${tmpfile}" --key "${subkey}" )
          [ -f "${tmpfile}" ] && result=$( \cat "${tmpfile}" )
        else
          result=$( __find_key_at_depth "${tmpfile}" "${subkey}" 0 )
        fi
        [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
      fi
      numlevels=$( decrement "${numlevels}" )
    done
    discard --channel "${chid}"
  fi

  if [ "${disregard_pds}" -eq "${YES}" ]
  then
    [ -n "${result}" ] && printf "%s\n" "${result}"
  else
    typeset pdsclass=$( get_pds_type --data "${result}" )
    if [ "${pdsclass}" == "${pdsmatch}" ]
    then
      [ -n "${result}" ] && printf "%s\n" "${result}"
    else
      return "${FAIL}"
    fi
  fi

  [ -n "${matching_section}" ] && [ "${matching_section}" -eq "${NO}" ] && return "${FAIL}"
  return "${PASS}"
}

extract_section()
{
  typeset fn=
  typeset key=

  OPTIND=1
  while getoptex "f: filename: k: key:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'filename' ) fn="${OPTARG}";;
    'k'|'key'      ) key="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${fn}" ] || [ ! -f "${fn}" ] || [ -z "${key}" ] && return "${FAIL}"
  [ $( __has_section "${fn}" "${key}" ) -eq "${NO}" ] && return "${FAIL}"

  typeset start_pt=$( \grep -n "^${key} " "${fn}" | \cut -f 1 -d ':' )
  typeset end_pt=$( __find_end_of_pu_section "${fn}" "${start_pt}" "${YES}" )

  start_pt=$(( start_pt + 1 ))
  typeset tmpfile=$( __extract_matching_lines "${fn}" "${start_pt}:${end_pt}" )
  __reduce_indentation "${tmpfile}" 1
  printf "%s\n" "${tmpfile}"
  return "${PASS}"
}

get_pds_key()
{
  typeset input

  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${input}" ] && return "${FAIL}"
  __get_pds_content --data "${input}" --field 1
  return $?
}

get_pds_size()
{
  typeset input

  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${input}" ] && return "${FAIL}"
  __get_pds_content --data "${input}" --field 3
  return $?
}

get_pds_type()
{
  typeset input

  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ -z "${input}" ] && return "${FAIL}"
  __get_pds_content --data "${input}" --field 2
  return $?
}

get_pds_value()
{
  typeset input

  OPTIND=1
  while getoptex "d: data:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'data' ) input="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${input}" ] && return "${FAIL}"
  __get_pds_content --data "${input}" --field '4-'
  return $?
}

get_pu_addon_options()
{
  [ -n "${NIMSOFT_PU_OPTIONS}" ] && printf "%s" "${NIMSOFT_PU_OPTIONS}"
  return "${PASS}"
}

run_pu_command()
{
  typeset ip
  typeset outputfile
  typeset recorder
  typeset retries=1
  typeset retry_delay=0
  typeset nimaddr
  typeset nimcmd

  OPTIND=1
  while getoptex "i: ip: f: outputfile: a: nimaddr: c: nimcmd: retries: retry-delay:" "$@"
  do
    case "${OPTOPT}" in
    'i'|'ip'          ) ip="${OPTARG}";;
    'a'|'addr'        ) nimaddr="${OPTARG}";;
    'f'|'outputfile'  ) filename="${OPTARG}";;
    'c'|'nimcmd'      ) nimcmd="${OPTARG}";;
    'r'|'recorder'    ) recorder="${OPTARG}";;
        'retries'     ) retries="${OPTARG}";;
        'retry-delay' ) retry_delay="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset localip=$( get_local_ip )

  typeset nimsoft_directory=$( get_nimsoft_directory )
  make_executable --exe pu "-p ${nimsoft_directory}"
  make_executable --exe ssh

  # If retry allowed, then loop over retries
  # If success found in pu assertion call then report success
  # else retry until limit reached otherwise return failure

  typeset identity="<${nimaddr} -- ${nimcmd}>"
  typeset pucount=0
  typeset times_failed=0
  while [ "${pucount}" -lt "${retries}" ]
  do
    pucount=$(( pucount + 1 ))
    if [ -x "${pu_exe}" ]
    then
      typeset nimsoft_user=$( get_nimsoft_user )
      typeset nimsoft_user_pswd=$( get_nimsoft_user_pswd )
      typeset pu_addons=$( get_pu_addon_options )

      if [ "${ip}" != "${localip}" ]
      then
        typeset sshuser=$( get_remote_user_id )
        [ $( is_empty --str "${recorder}" ) -eq "${NO}" ] && print_plain --message "ssh ${sshuser}@${ip} \"${pu_exe} -u ${nimsoft_user} -p ${nimsoft_user_pswd} ${pu_addons} ${nimaddr} ${nimcmd} $@\" -- ${pucount}" >> "${recorder}"
      else
        [ $( is_empty --str "${recorder}" ) -eq "${NO}" ] && print_plain --message "${pu_exe} -u ${nimsoft_user} -p ${nimsoft_user_pswd} ${pu_addons} ${nimaddr} ${nimcmd} $@ -- ${pucount}" >> "${recorder}"
      fi

      if [ -f "${outputfile}" ]
      then
	typeset count=1
	typeset newfile="${outputfile}${count}"
	while [ -f "${newfile}" ]
	do
	  count=$(( count + 1 ))
	  newfile="${outputfile}${count}"
	done
	\mv -f "${outputfile}" "${newfile}"
      fi

      typeset output=
      typeset PU_START_TIME=
      typeset PU_END_TIME
      if [ "${ip}" != "${localip}" ]
      then
        typeset sshuser=$( get_remote_user_id )
	PU_START_TIME=$( date )
	output=$( ssh ${sshuser}@${ip} "${pu_exe} -u ${nimsoft_user} -p ${nimsoft_user_pswd} ${pu_addons} ${nimaddr} ${nimcmd} $@ 2>&1" )
        PU_END_TIME=$( date )
	echo "${output}" > "${outputfile}"
      else
	PU_START_TIME=$( date )
        output=$( ${pu_exe} -u ${nimsoft_user} -p ${nimsoft_user_pswd} ${pu_addons} ${nimaddr} ${nimcmd} $@ > "${outputfile}" 2>&1 )
	PU_END_TIME=$( date )
      fi

      typeset matching_line=$( grep "failed:" "${outputfile}" )
      typeset RC="${PASS}"
      if [ -n "${matching_line}" ]
      then
	typeset error_phrases='error denied'
        typeset ep=
        for ep in ${error_phrases}
	do
	  printf "%s" "${matching_line}" | grep -q "${ep}"
	  typeset BRC=$?
	  if [ "${BRC}" -eq 0 ]
	  then
	    RC="${FAIL}"
	    break
	  fi
	done
      fi

      if [ "${RC}" -ne "${PASS}" ]
      then
        times_failed=$(( times_failed + 1 ))
        print_plain --message "   -- Failure in pu command '${nimcmd}' during retry ${pucount}" >> "${recorder}"
        print_plain --message "   -- Time for pu command --> Start = ${PU_START_TIME} | End = ${PU_END_TIME}" >> "${recorder}"
        sleep_func -s "${retry_interval}" --old-version
        continue
      else
        print_plain --message "   -- Success in pu command '${nimcmd}' during retry ${pucount}" >> "${recorder}"
	print_plain --message "   -- Time for pu command --> Start = ${PU_START_TIME} | End = ${PU_END_TIME}" >> "${recorder}"
        echo "${output}"
        break
      fi
    else
      return "${FAIL}"
    fi
  done

  printf "%s\n" "${times_failed}:${retries}:${identity}"
  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_FUNCTIONDIR}/filemgt.sh"
fi

__initialize_nim_pu
__prepared_nim_pu
