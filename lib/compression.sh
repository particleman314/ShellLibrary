#!/bin/sh
###############################################################################
# Copyright (c) 2016-2017.  All rights reserved. 
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
## @Software Package : Shell Automated Testing -- Compression
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.10
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __7z_decompress
#    __bunzip_decompress
#    __find_decompression_algorithm
#    __gunzip_decompress
#    __tar_decompress
#    __unzip_decompress
#    __unzip_decompress_passwd_option
#    compression
#    decompression
# 
###############################################################################

# shellcheck disable=SC2016,SC2039,SC1117

if [ -z "${__SUPPORTED_COMPRESSION_PROGRAMS}" ]
then
  __SUPPORTED_COMPRESSION_PROGRAMS='7z bzip gzip zip tar'
  __SUPPORTED_DECOMPRESSION_PROGRAMS='7z bunzip gunzip unzip tar'
fi

__initialize_compression()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )
    
  #SLCF_SHELL_RESOURCEDIR="${SLCF_SHELL_TOP}/resources"
  #SLCF_SHELL_FUNCTIONDIR="${SLCF_SHELL_TOP}/lib"
  #SLCF_SHELL_UTILDIR="${SLCF_SHELL_TOP}/utilities"

  __load __initialize_logging "${SLCF_SHELL_TOP}/lib/logging.sh"
  __load __initialize_machinemgt "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  __load __initialize_data_structures "${SLCF_SHELL_TOP}/lib/data_structures.sh"
  __load __initialize_cmdmgt "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  __load __initialize_cmd_interface "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"

  __COMPRESSION_LOG_CHANNEL='DECOMPRESS'
  __DECOMPRESSION_OPTIONS='i: input: o: output-dir: save-partial keep-orig'

  __COMPRESSION_OPTIONS=
  __initialize "__initialize_compression"
}

__prepared_compression()
{
  __prepared "__prepared_compression"
}

__7z_decompress()
{
  __debug $@

  typeset RC="${PASS}"

  if [ -z "${uncompressor_7z_exe}" ]
  then
    typeset uncompressors=
    list_add --object 'uncompressors' --data '7z 7za 7zr'
  
    typeset found_uncompressor="${NO}"
    typeset exe=
    for exe in $( list_data --object 'uncompressors' )
    do
      make_executable --exe "${exe}" --alias 'uncompressor_7z'
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
        found_uncompressor="${YES}"
        break
      fi
    done

    [ "${found_uncompressor}" -eq "${NO}" ] && return "${FAIL}"
  fi

  typeset infile=
  typeset outdir=
  typeset save_partial="${NO}"
  typeset keep_original="${NO}"

  OPTIND=1
  while getoptex "${__DECOMPRESSION_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'        ) infile="${OPTARG}";;
    'o'|'output-dir'   ) outdir="${OPTARG}";;
        'save-partial' ) save_partial="${YES}";;
        'keep-orig'    ) keep_original="${YES}";;
     esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${infile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${infile}" ] && return "${FAIL}"

  ###
  ### See if the input file is a relative path versus an absolute path
  ###
  [ "$( \basename "${infile}" )" -eq "${infile}" ] && infile="./${infile}"
  infile="$( \readlink -f "${infile}" )"

  typeset reduced_infile="$( \basename "${infile}" )"

  ###
  ### Determine if original should be kept...
  ###
  [ "${keep_original}" -eq "${YES}" ] && \cp -f "${infile}" "${infile}.keep"

  outdir="$( __make_compression_dir "${outdir}" )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset make_directory=$( get_element --data "${outdir}" --id 2 --separator ':' )
  outdir="$( get_element --data "${outdir}" --id 1 --separator ':' )"

  typeset jumppt="$( \pwd -L )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    cd "${outdir}" >/dev/null 2>&1 || return "${FAIL}"
    \cp -f "${infile}" "${reduced_infile}"
  fi

  ###
  ### Need to use the reduced_infile when moving to a different directory
  ###
  typeset decompress_out="$( call --cmd "${uncompressor_7z_exe} -e \"${reduced_infile}\" -o\"${outdir}\" ${__COMPRESSION_OPTIONS}" )"
  RC="$( get_last_cmd_code )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    \rm -f "${reduced_infile}"
    cd "${jumppt}" > /dev/null 2>&1 || return "${FAIL}"
  fi

  append_output --channel "${__COMPRESSION_LOG_CHANNEL}" --data "${decompress_out}" --raw

  __handle_resultant_decompression "${RC}" "${make_directory}" "${outdir}" "${save_partial}"

  [ "${keep_original}" -eq "${YES}" ] && \mv -f "${infile}.keep" "${infile}"
  [ "${RC}" -eq "${PASS}" ] && __reset_compression_options

  return "${RC}"
}

__bunzip_decompress()
{
  __debug $@

  typeset RC="${PASS}"

  if [ -z "${bzip2_exe}" ]
  then
    make_executable --exe 'bzip2'
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  typeset infile=
  typeset outdir='.'
  typeset save_partial="${NO}"
  typeset keep_original="${NO}"

  OPTIND=1
  while getoptex "${__DECOMPRESSION_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'        ) infile="${OPTARG}";;
    'o'|'output-dir'   ) outdir="${OPTARG}";;
        'save-partial' ) save_partial="${YES}";;
        'keep-orig'    ) keep_original="${YES}";;
     esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${infile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${infile}" ] && return "${FAIL}"

  ###
  ### See if the input file is a relative path versus an absolute path
  ###
  [ "$( \basename "${infile}" )" -eq "${infile}" ] && infile="./${infile}"
  infile="$( \readlink -f "${infile}" )"

  typeset reduced_infile="$( \basename "${infile}" )"

  ###
  ### Determine if original should be kept...
  ###
  [ "${keep_original}" -eq "${YES}" ] && \cp -f "${infile}" "${infile}.keep"

  outdir="$( __make_compression_dir "${outdir}" )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset make_directory=$( get_element --data "${outdir}" --id 2 --separator ':' )
  outdir="$( get_element --data "${outdir}" --id 1 --separator ':' )"
  typeset jumppt="$( \pwd -L )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    cd "${outdir}" >/dev/null 2>&1 || return "${FAIL}"
    \cp -f "${infile}" "${reduced_infile}"
  fi

  ###
  ### Need to use the reduced_infile when moving to a different directory
  ###
  typeset decompress_out="$( call --cmd "${bzip2_exe} -d -f ${__COMPRESSION_OPTIONS} \"${reduced_infile}\"" )"
  RC="$( get_last_cmd_code )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    \rm -f "${reduced_infile}"
    cd "${jumppt}" > /dev/null 2>&1 || return "${FAIL}"
  fi

  append_output --channel "${__COMPRESSION_LOG_CHANNEL}" --data "${decompress_out}" --raw

  __handle_resultant_decompression "${RC}" "${make_directory}" "${outdir}" "${save_partial}"

  [ "${keep_original}" -eq "${YES}" ] && \mv -f "${infile}.keep" "${infile}"
  [ "${RC}" -eq "${PASS}" ] && __reset_compression_options

  return "${RC}"
}

__find_decompression_algorithm()
{
  typeset orig_filename="$1"
  typeset filename="${orig_filename}"
  typeset decompress=

  if [ -n "${filename}" ]
  then
    typeset needs_decompression="${YES}"
    while [ "${needs_decompression}" -eq "${YES}" ]
    do
      typeset ext="$( get_extension "${filename}" )"
      if [ -n "${ext}" ]
      then
        case "${ext}" in
        'zip'       ) queue_add --object 'decompress' --data '__unzip_decompress';;
        'bz2'       ) queue_add --object 'decompress' --data '__bunzip_decompress';;
        'gz'        ) queue_add --object 'decompress' --data '__gunzip_decompress';;
        'tar'       ) queue_add --object 'decompress' --data '__tar_decompress';;
        '7z'|'7za'  ) queue_add --object 'decompress' --data '__7z_decompress';;
        *           ) needs_decompression="${NO}";;
        esac
        [ "${needs_decompression}" -eq "${NO}" ] && break
        filename="$( remove_extension "${filename}" )"
      fi
    done
  fi


  if [ "$( queue_size --object 'decompress' )" -gt 0 ]
  then
    printf "%s\n" "$( queue_data --object 'decompress' )"
    queue_clear --object 'decompress'
    return "${PASS}"
  else
    return "${FAIL}"
  fi
}

__gunzip_decompress()
{
  __debug $@

  typeset RC="${PASS}"

  if [ -z "${gzip_exe}" ]
  then
    make_executable --exe 'gzip'
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  typeset infile=
  typeset outdir='.'
  typeset save_partial="${NO}"
  typeset keep_original="${NO}"

  OPTIND=1
  while getoptex "${__DECOMPRESSION_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'        ) infile="${OPTARG}";;
    'o'|'output-dir'   ) outdir="${OPTARG}";;
        'save-partial' ) save_partial="${YES}";;
        'keep-orig'    ) keep_original="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${infile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${infile}" ] && return "${FAIL}"

  ###
  ### See if the input file is a relative path versus an absolute path
  ###
  [ "$( \basename "${infile}" )" -eq "${infile}" ] && infile="./${infile}"
  infile="$( \readlink -f "${infile}" )"

  typeset reduced_infile="$( \basename "${infile}" )"

  ###
  ### Determine if original should be kept...
  ###
  [ "${keep_original}" -eq "${YES}" ] && \cp -f "${infile}" "${infile}.keep"

  outdir="$( __make_compression_dir "${outdir}" )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset make_directory=$( get_element --data "${outdir}" --id 2 --separator ':' )
  outdir="$( get_element --data "${outdir}" --id 1 --separator ':' )"
  typeset jumppt="$( \pwd -L )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    cd "${outdir}" >/dev/null 2>&1 || return "${FAIL}"
    \cp -f "${infile}" "${reduced_infile}"
  fi

  ###
  ### Need to use the reduced_infile when moving to a different directory
  ###
  typeset decompress_out="$( call --cmd "${gzip_exe} -d -f ${__COMPRESSION_OPTIONS} \"${reduced_infile}\"" )"
  RC="$( get_last_cmd_code )"

  if [ "${outdir}" != "${jumppt}" ]
  then
    \rm -f "${reduced_infile}"
    cd "${jumppt}" > /dev/null 2>&1 || return "${FAIL}"
  fi

  append_output --channel "${__COMPRESSION_LOG_CHANNEL}" --data "${decompress_out}" --raw

  __handle_resultant_decompression "${RC}" "${make_directory}" "${outdir}" "${save_partial}"

  [ "${keep_original}" -eq "${YES}" ] && \mv -f "${infile}.keep" "${infile}"
  [ "${RC}" -eq "${PASS}" ] && __reset_compression_options

  return "${RC}"
}

__handle_resultant_decompression()
{
  typeset RC="$1"
  typeset make_directory="$2"
  typeset outdir="$3"
  typeset save_partial="$4"

  if [ "${RC}" -ne "${PASS}" ]
  then
    if [ "${make_directory}" -eq "${YES}" ]
    then
      if [ "${save_partial}" -eq "${NO}" ]
      then
        [ -d "${outdir}" ] && \rm -rf "${outdir}"
      else
        print_plain --msg "${outdir}"
      fi
    fi
  else
    print_plain --msg "${outdir}"
  fi

  return "${PASS}"
}

__make_compression_dir()
{
  typeset outdir="$1"

  outdir="$( \readlink -f "${outdir}" )"

  [ -z "${outdir}" ] && outdir="$( make_temp_dir )"
  
  if [ ! -d "${outdir}" ]
  then
    if [ -e "${outdir}" ]
    then
      print_plain --msg "${outdir}:${NO}"
      return "${FAIL}"
    else
      print_plain --msg "${outdir}:${YES}"
      return "${PASS}"
    fi
  fi

  print_plain --msg "${outdir}:${NO}"
  return "${PASS}"
}

__reset_compression_options()
{
  __COMPRESSION_OPTIONS=
  return "${PASS}"
}

__set_compression_options()
{
  __COMPRESSION_OPTIONS="$@"
  return "${PASS}"
}

__tar_decompress()
{
  __debug $@

  typeset RC="${PASS}"

  if [ -z "${tar_exe}" ]
  then
    make_executable --exe 'tar'
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  typeset infile=
  typeset outdir='.'
  typeset save_partial="${NO}"
  typeset keep_original="${NO}"

  OPTIND=1
  while getoptex "${__DECOMPRESSION_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'        ) infile="${OPTARG}";;
    'o'|'output-dir'   ) outdir="${OPTARG}";;
        'save-partial' ) save_partial="${YES}";;
        'keep-orig'    ) keep_original="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${infile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${infile}" ] && return "${FAIL}"

  ###
  ### See if the input file is a relative path versus an absolute path
  ###
  [ "$( \basename "${infile}" )" -eq "${infile}" ] && infile="./${infile}"
  infile="$( \readlink -f "${infile}" )"

  ###
  ### Determine if original should be kept...
  ###
  [ "${keep_original}" -eq "${YES}" ] && \cp -f "${infile}" "${infile}.keep"

  outdir="$( __make_compression_dir "${outdir}" )"
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset make_directory="$( get_element --data "${outdir}" --id 2 --separator ':' )"
  outdir="$( get_element --data "${outdir}" --id 1 --separator ':' )"

  typeset decompress_out="$( call --cmd "${tar_exe} xvf \"${infile}\" -C \"${outdir}\" $@" )"
  RC="$( get_last_cmd_code )"

  append_output --channel "${__COMPRESSION_LOG_CHANNEL}" --data "${decompress_out}" --raw

  __handle_resultant_decompression "${RC}" "${make_directory}" "${outdir}" "${save_partial}"

  [ "${keep_original}" -eq "${YES}" ] && \mv -f "${infile}.keep" "${infile}"
  [ "${RC}" -eq "${PASS}" ] && __reset_compression_options

  return "${RC}"
}

__unzip_decompress()
{
  __debug $@

  typeset RC="${PASS}"

  if [ -z "${unzip_exe}" ]
  then
    make_executable --exe 'unzip'
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"
  fi

  typeset infile=
  typeset outdir='.'
  typeset save_partial="${NO}"
  typeset keep_original="${NO}"

  OPTIND=1
  while getoptex "${__DECOMPRESSION_OPTIONS}" "$@"
  do
    case "${OPTOPT}" in
    'i'|'input'        ) infile="${OPTARG}";;
    'o'|'output-dir'   ) outdir="${OPTARG}";;
        'save-partial' ) save_partial="${YES}";;
        'keep-orig'    ) keep_original="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${infile}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${infile}" ] && return "${FAIL}"

  ###
  ### See if the input file is a relative path versus an absolute path
  ###
  [ "$( \basename "${infile}" )" -eq "${infile}" ] && infile="./${infile}"
  infile="$( \readlink -f "${infile}" )"

  typeset reduced_infile="$( \basename "${infile}" )"

  ###
  ### Determine if original should be kept...
  ###
  [ "${keep_original}" -eq "${YES}" ] && \cp -f "${infile}" "${infile}.keep"

  outdir=$( __make_compression_dir "${outdir}" )
  RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${RC}"

  typeset make_directory="$( get_element --data "${outdir}" --id 2 --separator ':' )"
  outdir="$( get_element --data "${outdir}" --id 1 --separator ':' )"

  typeset decompress_out="$( call --cmd "${unzip_exe} -o ${__COMPRESSION_OPTIONS} -d \"${outdir}\" \"${infile}\"" $@ )"
  RC="$( get_last_cmd_code )"

  append_output --channel "${__COMPRESSION_LOG_CHANNEL}" --data "${decompress_out}" --raw

  __handle_resultant_decompression "${RC}" "${make_directory}" "${outdir}" "${save_partial}"

  [ "${keep_original}" -eq "${YES}" ] && \mv -f "${infile}.keep" "${infile}"
  [ "${RC}" -eq "${PASS}" ] && __reset_compression_options

  return "${RC}"
}

compression()
{
  typeset filename=
  typeset compressor=
  typeset passwd=
  typeset output_dir=

  typeset RC="${PASS}"

  list_clear --object 'compress_object'
  
  OPTIND=1
  while getoptex "f: compress-file: p: passwd: o: output-dir i: input:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'compress-file'  ) filename="${OPTARG}";;
    'p'|'passwd'         ) passwd="${OPTARG}";;
    'o'|'output-dir'     ) output_dir="${OPTARG}";;
    'i'|'input'          ) list_add --object 'compress_object' --data "--input___${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  [ "$( list_size --object 'compress_input' )" -lt 1 ] && return "${FAIL}"
  
  typeset algo="$( __find_decompression_algorithm "${filename}" )"
  typeset compressor="$( __translate_algorithm "${algo}" )"
  
  if [ "$( fn_exists "__${compressor}_compress" )" -eq "${YES}" ]
  then
    typeset pwd_options=
    if [ "$( fn_exists "__${compressor}_compressor_passwd_option" )" -eq "${YES}" ] && [ "$( is_empty --str "${passwd}" )" -eq "${NO}" ]
    then
      eval "pwd_options=\"\$( __${compressor}_compress_passwd_option ${passwd} )\""
    fi
    typeset inputs="$( list_data --object 'compress_input' ) | \sed 's#--input___#--input #' )"
    eval "__${compressor}_compress --output \"${output_dir}/${filename}\" ${inputs} ${pwd_options}"
    RC=$?
  fi
  
  printf "%s\n" "${output_dir}/${filename}"
  
  return "${RC}"
}

decompression()
{
  typeset filename=
  typeset decompressor=
  typeset passwd=
  typeset output_dir=

  typeset RC="${PASS}"

  OPTIND=1
  while getoptex "f: compress-file: o: output-dir" "$@"
  do
    case "${OPTOPT}" in
    'f'|'compress-file'  ) filename="${OPTARG}";;
    'd'|'decompressor'   ) decompressor="${OPTARG}";;
    'p'|'passwd'         ) passwd="${OPTARG}";;
    'o'|'output-dir'     ) output_dir="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  ###
  ### Verify the input file is legitimate
  ###
  [ "$( is_empty --str "${filename}" )" -eq "${YES}" ] && return "${FAIL}"
  [ ! -f "${filename}" ] && return "${FAIL}"

  [ "$( is_empty --str "${output_dir}" )" -eq "${YES}" ] && output_dir=$( make_temp_dir )
  [ ! -d "${output_dir}" ] && \mkdir -p "${output_dir}"

  decompressor_algorithm="$( __find_decompression_algorithm "${filename}" )"
  [ "$( is_empty --str "${decompressor_algorithm}" )" -eq "${YES}" ] && return "${FAIL}"
 
  typeset da=
  for da in ${decompressor_algorithm}
  do
    eval "${da} --input \"${filename}\" --output-dir \"${output_dir}\""
    RC=$?
    [ "${RC}" -ne "${PASS}" ] && break
    filename="$( remove_extension "${filename}" )"
  done
  printf "%s\n" "${output_dir}"
  return "${RC}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/logging.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/machinemgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/data_structures.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/cmdmgt.sh"
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/cmd_interface.sh"
fi

__initialize_compression
__prepared_compression
