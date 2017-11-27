#!/bin/sh
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
## @Author           : Mike Klusman
## @Software Package : Shell Automated Testing -- Machine Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.02
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    add_to_envvar
#    convert_path
#    convert_path_for_machine
#    convert_to_unc
#    find_available_drive_letter
#    find_mount_point
#    is_abs_path
#    is_filer_path
#    is_unc_path
#    is_windows_network_path
#    make_logfile
#    make_temp_dir
#    make_temp_file
#    make_unix_windows_path
#    make_windows_mount_points
#    make_network_drive_map
#    map_network_drive
#    make_path_to
#    parse_net_use
#    relative_to_absolute
#    relative_path
#    remove_mount_points
#    rotate_file
#    timed_rotation_of_file
#    unmap_network_drive
#
###############################################################################

# shellcheck disable=SC2016,SC2039,SC2068,SC2120,SC2034,SC2086,SC1117,SC2181,SC2046

__initialize_machinemgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_base_machinemgt "${SLCF_SHELL_TOP}/lib/base_machinemgt.sh"
  [ -z "${__MAXIMUM_LOGFILE_LINES}" ] && __MAXIMUM_LOGFILE_LINES=2000

  __initialize "__initialize_machinemgt"
}

__prepared_machinemgt()
{
  __prepared "__prepared_machinemgt"
}

add_to_envvar()
{
  __debug $@

  __ensure_local_machine_identified
  
  typeset data=
  typeset envvar='PATH'
  typeset loctype='prepend'
  typeset sep="${SEPARATOR}"

  OPTIND=1
  while getoptex "d: data: e: envvar: l. location. s. separator." "$@"
  do
    case "${OPTOPT}" in
    'd'|'data'      ) data="${OPTARG}";;
    'e'|'envvar'    ) envvar="${OPTARG}";;
    'l'|'location'  ) loctype="${OPTARG}";;
    's'|'separator' ) sep="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${data}" )" -eq "${YES}" ] && return "${PASS}"

  typeset dummy=$( set | \grep "^${envvar}=" | \cut -f 2 -d '=' )
  if [ "$( is_empty --str "${dummy}" )" -eq "${YES}" ]
  then
    dummy="${data}"
  else
    if [ "x${loctype}" == "xappend" ]
    then
      dummy="${dummy}${sep}${data}"
    else
      dummy="${data}${sep}${dummy}"
    fi
  fi

  eval "${envvar}='${data}'"
  printf -v "${envvar}" "%s" "${dummy}"
  return "${PASS}"
}

convert_path()
{
  __debug $@
    
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset path=
  typeset style=
  
  OPTIND=1
  while getoptex "p: path: o: style:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'  ) path="${OPTARG}";;
    'o'|'style' ) style="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -n "${path}" ]
  then
    if [ "$( is_windows_machine )" -eq "${YES}" ]
    then
      typeset xxx=

      case "${style}" in
      'win'  |'windows')  xxx=$( cygpath -w "${path}" );;
      'unix' |'linux')    xxx=$( cygpath -u "${path}" );;
      'path')             xxx=$( cygpath -p "${path}" );;
      'mixed'|*)          xxx=$( cygpath -m "${path}" );;
      esac

      print_plain --format "%q" --message "${xxx}"
    else
      print_plain --format "%q" --message "${path}"
    fi
  fi
  return "${PASS}"
}

convert_path_for_machine()
{
  __debug $@
  
  typeset path=
  typeset osstyle="${OSVARIETY}"

  OPTIND=1
  while getoptex "p: path: o: style:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'  ) path="${OPTARG}";;
    'o'|'style' ) osstyle="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${path}" )" -eq "${YES}" ] && return "${FAIL}"

  path="$( make_unix_windows_path --path "$( convert_to_unc --path "${path}" )" --style "${osstyle}" )"
  print_plain --format "%q" --message "$( remove_trailing_slash --str "${path}" )"
  return "${PASS}"
}

convert_to_unc()
{
  __debug $@
    
  typeset path=
  typeset userid="$( get_user_id )"
  
  OPTIND=1
  while getoptex "p: path: u. user-id." "$@"
  do
    case "${OPTOPT}" in
    'p'|'path' )    path="${OPTARG}";;
    'u'|'user-id' ) userid="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${path}" )" -eq "${YES}" ] && return "${FAIL}"
  
  if [ "$( is_unc_path --path "${path}" )" -eq "${YES}" ]
  then
    print_plain --message "${path}"
    return "${PASS}"
  fi

  if [ "$( is_windows_network_path --path "${path}" )" -eq "${YES}" ]
  then
    typeset pathlen="${#path}"
    typeset driveletter="${path:0:2}"
    typeset subdir="${path:3:${pathlen}}"
    path="$( convert_path --path "$( parse_net_use --user "${userid}" --root-path "${driveletter}" --direction reverse )" --style 'unix' )"
    path="${path}/${subdir}"
  fi

  print_plain --format "%q\n" --message "${path}"
  return "${PASS}"
}

find_available_drive_letter()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"
	
  typeset alphabet=
  typeset output=
  
  for alphabet in z y x v u t s r p o n m l k j i h g f e
  do
    output="$( ls --color=none "${alphabet}:" >/dev/null 2>&1 )"
    RC=$?
    if [ "${RC}" -ne "${PASS}" ]
    then
      print_plain --message "$( to_upper ${alphabet} )"
      return "${PASS}"
    fi
  done
  return "${FAIL}"
}

find_mount_point()
{
  __debug $@
    
  typeset dummy=

  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset path=
  
  OPTIND=1
  while getoptex "p: path:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path' ) path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${path}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    typeset varvalue="${path}"
    if [ "$( is_windows_network_path --path "${path}" )" -eq "${YES}" ] && [ "${#varvalue}" -eq 3 ]
    then
      print_plain --message "${varvalue}"
      return "${PASS}"
    fi

    # Need to check to see if path is already a "root" for windows (i.e. no subdir components)
    typeset rootpath="$( print_plain --message "${varvalue}" | \cut -f 1-4 -d '/' )"
    if [ "x${rootpath}" == "x${varvalue}" ]
    then
      typeset driveletter="$( parse_net_use --user "${userid}" --root-path "${rootpath}" --direction forward )"
      if [ -n "${driveletter}" ]
      then
	      typeset cmd="dummy=\$( print_plain --message \"${varvalue}\" | sed -e 's#${rootpath}#${driveletter}:#' )"
	      eval "${cmd}"
      fi
      print_plain --message "${dummy}"
      return "${PASS}"
    fi

    typeset current_dirname="${varvalue}"
    typeset found="${NO}"

    while [ "${found}" -ne "${YES}" ] && [ -n "${current_dirname}" ]
    do
      if [ "$( is_unc_path --path "${current_dirname}" )" -eq "${YES}" ]
      then
        current_dirname="$( \dirname "${current_dirname}" )"
        typeset driveletter="$( parse_net_use --user "${userid}" --root-path "${current_dirname}" )"
	      if [ -n "${driveletter}" ]
        then
	        typeset cmd="dummy=\$( print_plain --message \"${varvalue}\" | sed -e 's#${current_dirname}#${driveletter}:#' )"
	        eval "${cmd}"
          found="${YES}"
	      fi
      else
	      dummy="${varvalue}"
	      if [ ! -d "${varvalue}" ]
	      then
	        print_plain --message "[ ERROR ] Unable to find existing location < ${varvalue} >"
	        return "${FAIL}"
	      fi
      fi
    done
  else
    dummy="${path}"
  fi

  print_plain --message "${dummy}"
  return "${PASS}"
}

is_abs_path()
{
  __debug $@
  
  typeset path=
  
  OPTIND=1
  while getoptex "p. path." "$@"
  do
    case "${OPTOPT}" in
   'p'|'path' ) path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${path}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
    return "${PASS}"
  fi

  if [ "$( is_windows_machine )" -eq "${YES}" ]
  then
    print_plain --message "$( is_unc_path --path \"${path}\" )"
  else
    typeset firstchar="${path:0:1}"
    if [ "x${firstchar}" == "x/" ]
    then
      print_plain --message "${YES}"
    else
      print_plain --message "${NO}"
    fi
  fi
  return "${PASS}"
}

is_filer_path()
{
  __debug $@
  
  typeset path=
  typeset dmapfile=

  OPTIND=1
  while getoptex "p: path: m: map-file:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'     ) path="${OPTARG}";;
    'm'|'map-file' ) dmapfile="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${dmapfile}" )" -eq "${YES}" ] || [ ! -f "${dmapfile}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
 
  typeset rootpath="$( \dirname "${path}" )"
  typeset line=
  
  while read -u 9 -r line
  do
    [ "$( is_empty --str "${line}" )" -eq "${YES}" ] && continue

    typeset unix_filer_path="$( print_plain --message "${line}" | \cut -f 2 -d '|' )"
    if [ "x${path}" == "x${unix_filer_path}" ]
    then
      print_plain --message "${YES}"
      return "${PASS}"
    fi
  done 9< "${dmapfile}"
  
  print_plain --message "${NO}"
  return "${FAIL}"
}

is_unc_path()
{
  __debug $@

  __ensure_local_machine_identified
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
  
  if [ "$( is_windows_machine )" -eq "${NO}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
  
  typeset path=
  
  OPTIND=1
  while getoptex "p. path." "$@"
  do
    case "${OPTOPT}" in
    'p'|'path' ) path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${path}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
  
  typeset unc_str="${path:(2)}"
  if [ "x${unc_str}" == "x//" ]
  then
    print_plain --message "${YES}"
  else 
    print_plain --message "${NO}"
  fi
  return "${PASS}"
}

is_windows_network_path()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  if [ "${RC}" -ne "${PASS}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
  
  if [ "$( is_windows_machine )" -eq "${NO}" ]
  then
    print_plain --message "${NO}"
    return "${FAIL}"
  fi
  
  typeset path=
  
  OPTIND=1
  while getoptex "p: path:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path' ) path="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  [ "$( is_empty --str "${path}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset colon_str="${path:1:1}"

  if [ "x${colon_str}" == "x:" ]
  then
    print_plain --message "${YES}"
  else
    print_plain --message "${NO}"
  fi
  return "${PASS}"
}

make_logfile()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset directory="$( get_temp_dir )"
  typeset logfilename="logfile.${__TEMP_PATTERN}"
  typeset permissions=777

  OPTIND=1
  while getoptex "d: directory: f: log-file: p: permissions:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'directory'   ) directory="${OPTARG}";;
    'f'|'log-file'    ) logfilename="${OPTARG}";;
    'p'|'permissions' ) permissions="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "x${logfilename}" == "xlogfile.${__TEMP_PATTERN}" ]
  then
    make_temp_file --directory "${directory}" --file "${logfilename}"
    RC=$?
  else
    typeset fulldir="${directory}/$( \dirname '${logfilename}' )"
    \mkdir -p "${fulldir}"
    \touch "${directory}/${logfilename}"
    \chmod -R "${permissions}" "${fulldir}"
    RC=${PASS}
	
    print_plain --message "${directory}/${logfilename}"
  fi
  return "${RC}"
}

#make_linux_mount_points()
#{
#
#}

make_windows_mount_points()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ $# -eq 0 ] return "${FAIL}"

  # First pass -- determine common paths to make mapped drive letters
  # This will cut down on unnecessary drive letter mapping and allow for better
  # reusability
  typeset known_root_paths=
  typeset path_rep=
  typeset krp=

  for path_rep in $@
  do
    typeset cmd="typeset path=\${$path_rep}"
    eval "${cmd}"

    typeset rootpath=
    if [ "$( is_windows_machine )" -eq "${YES}" ]
    then
      rootpath=$( print_plain --message "${path}" | \cut -f 1-4 -d '/' )
    else
      rootpath=$( print_plain --message "${path}" | \cut -f 1-3 -d '/' )
    fi

    typeset found="${NO}"
    for krp in ${known_root_paths}
    do
      if [ "x${krp}" == "x${rootpath}" ]
      then
	      found="${YES}"
	      break
      fi
    done

    if [ "${found}" -eq "${NO}" ]
    then
      if [ "$( is_empty --str "${known_root_paths}" )" -eq "${YES}" ]
      then
	      known_root_paths="${rootpath}"
      else
	      known_root_paths="${known_root_paths} ${rootpath}"
      fi
    fi
  done

  # Second pass is to store newly created driveletter mappings so that they are
  # released upon completion of the script
  for krp in ${known_root_paths}
  do
    typeset pre_existing_driveletter="$( find_mount_point --path "${krp}" )"
    if [ "x${pre_existing_driveletter}" == "x${krp}" ]
    then
      typeset new_driveletter="$( make_network_drive_map --drive-path "${krp}" )"
      preexist_key="$( hget --map "add_drivemaps" --key "created" )"
      if [ "$( is_empty --str "${preexist_key}" )" -eq "${YES}" ]
      then
	      hput --map "add_drivemaps" --key "created" --value "${new_driveletter}"
      else
	      hput --map "add_drivemaps" --key "created" --value "${preexist_key} ${new_driveletter}"
      fi
    fi
  done

  sleep_func -s 5

  # Third pass is to remake all necessary path vars using newly created maps
  for path_rep in $@
  do
    typeset cmd="typeset path=\${$path_rep}"
    eval "${cmd}"

    cmd="${path_rep}=\$( find_mount_point --path \"${path}\" )"
    eval "${cmd}"
    print_plain --message "Resetting < ${path_rep} > using mapped drive letter..."
  done
  return "${PASS}"
}

make_network_drive_map()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"
	
  typeset drivepath=
  
  OPTIND=1
  while getoptex "d: drive-path:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'drive-path' ) drivepath="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${drivepath}" )" -eq "${YES}" ] && return "${FAIL}"
  
  typeset driveletter="$( find_available_drive_letter )"
  if [ $? -ne "${PASS}" ]
  then
    print_plain --message "[ ERROR ] Unable to find drive letter to map path < ${drivepath} > to be used.  Please cleanup some network drive mappings"
    return "${FAIL}"
  fi

  map_network_drive --path "${drivepath}" --drive-letter "${driveletter}"
  if [ $? -ne "${PASS}" ]
  then
    print_plain --message "[ ERROR ] Unable to map drive < ${drivepath} > to drive letter < ${driveletter} >!"
    return "${FAIL}"
  fi

  print_plain --message "${driveletter}"
  return "${PASS}"
}

make_temp_dir()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset user_directory=

  OPTIND=1
  while getoptex "d: directory:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'directory' ) user_directory="$OPTARG";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${user_directory}" )" -eq "${YES}" ] && user_directory="$( get_temp_dir )"

  typeset tmpdir="$( \mktemp -d tmpdir.${__TEMP_PATTERN} )"
  RC=$?
  if [ "${RC}" -eq "${PASS}" ]
  then
    [ ! -d "${user_directory}/${tmpdir}" ] && \mv -f "${tmpdir}" "${user_directory}" > /dev/null 2>&1 
    print_plain --message "${user_directory}/$( \basename ${tmpdir} )"
  fi
  return "${RC}"
}

make_temp_file()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset user_directory=
  typeset userfile=

  OPTIND=1
  while getoptex "d. directory. f. file." "$@"
  do
    case "${OPTOPT}" in
    'd'|'directory' ) user_directory="$OPTARG";;
    'f'|'file'      ) userfile="$OPTARG";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${user_directory}" )" -eq "${YES}" ] && user_directory="$( get_temp_dir )"
  user_directory=$( \readlink -f "${user_directory}" )

  typeset tmpfile=$( \mktemp tmp.${__TEMP_PATTERN} )
  RC=$?
  
  if [ "${RC}" -eq "${PASS}" ]
  then
    typeset tmpfiledir="$( \dirname "${tmpfile}" )"
    [ "$( is_empty "${userfile}" )" -eq "${YES}" ] && userfile="$( \basename "${tmpfile}" )"
    \mkdir -p "${user_directory}"
    [ "${tmpfiledir}" != "${user_directory}" ] && \mv -f "${tmpfile}" "${user_directory}/${userfile}" > /dev/null 2>&1
    print_plain --message "${user_directory}/${userfile}"
  fi
  return "${RC}"
}

make_unix_windows_path()
{
  __debug $@
  
  typeset path=
  typeset style='unix'
  
  OPTIND=1
  while getoptex "p: path: o: style:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'  ) path="${OPTARG}";;
    'o'|'style' ) style="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${path}" )" -eq "${YES}" ] && return "${FAIL}"

  if [ "x${style}" == "xunix" ] || [ "x${style}" == "xlinux" ]
  then
    if [ "$( is_unc_path --path "${path}" )" -eq "${YES}" ]
    then
      typeset unix_value="$( map_path_to --path "${path}" --style unix )"
      if [ "$( is_empty --str "${unix_value}" )" -eq "${NO}" ]
      then
	      print_plain --message "${unix_value}"
      else
	      print_plain --message "${path}"
      fi
    else
      if [ "$( is_windows_network_path --path "${path}" )" -eq "${YES}" ]
      then
	      typeset windows_path="$( convert_to_unc --path "${path}" )"
	      make_unix_windows_path --path "${windows_path}" --style "${style}"
      else
	      print_plain --message "${path}"
      fi
    fi
  else
    typeset windows_value="$( map_path_to --path "${path}" --style windows )"
    if [ -n "${windows_value}" ]
    then
      print_plain --message "${windows_value}"
    else
      print_plain --message "${path}"
    fi
  fi
  return "${PASS}"
}

map_network_drive()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"

  OPTIND=1
  while getoptex "d. drive-letter. p: path:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'         ) path="${OPTARG}";;
    'd'|'drive-letter' ) drive_letter="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${drive_letter}" ] && return "${FAIL}"

  typeset drivepath="$( convert_path --path "${path}" --style windows )"

  typeset cmd="net use ${drive_letter}: '${path}'> /dev/null 2>&1"
  eval "${cmd}"
  return $?
}

map_path_to()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset path=
  typeset style='unix'

  OPTIND=1
  while getoptex "p: path: o: style: f: drivemap-file:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'path'          ) path="${OPTARG}";;
    'o'|'style'         ) style="${OPTARG}";;
    'd'|'drivemap-file' ) drvmap_file="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  typeset rootpath=
  typeset subdirpath=
  typeset reverse_lookup_path=

  if [ "x${style}" == "xwindows" ]
  then
    rootpath="$( print_plain --message "${path}" | \cut -f 1-3 -d '/' )"
    reverse_lookup_path="$( \grep "${rootpath}" "${drvmap_file}" 2>/dev/null | \cut -f 1 -d ':' )"
    subdirpath="$( print_plain --message "${path}" | \cut -f 4- -d '/' )"
  else
    if [ "$( is_unc_path --path "${path}" )" -eq "${YES}" ]
    then
      rootpath="$( print_plain --message "${path}" | \cut -f 1-4 -d '/' )"
      subdirpath="$( print_plain --message "${path}" | \cut -f 5- -d '/' )"
    else
      rootpath="${path}"
    fi
    [ "$( is_empty --str "${drvmap_file}" )" -eq "${NO}" ] && [ -f "${drvmap_file}" ] && reverse_lookup_path=$( \grep "${rootpath}" "${drvmap_file}" 2>/dev/null | \cut -f 2 -d '|' )
    
    [ "$( is_empty --str "${reverse_lookup_path}" )" -eq "${YES}" ] && reverse_lookup_path="${rootpath}"
  fi
  
  print_plain --message "${reverse_lookup_path}/${subdirpath}"
  return "${PASS}"
}

parse_net_use()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"

  typeset user=
  typeset style='forward'
  typeset chop_trailing_slash="${NO}"
  
  OPTIND=1
  while getoptex "u: user: r: root-path: d: direction: remove-trail-slash" "$@"
  do
    case "${OPTOPT}" in
    'u'|'user'           ) user="${OPTARG}";;
    'r'|'root-path'      ) path="${OPTARG}";;
    'd'|'direction'      ) style="${OPTARG}";;
    'remove-trail-slash' ) chop_trailing_slash="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  typeset tmpfile="$( make_temp_file --file ".network_mapped_drives_${OS_SPEC}_${user}" )"
  net use > "${tmpfile}"

  typeset windows_path="$( escapify "$( convert_path --path "${path}" --style 'windows' )" )"

  [ "${chop_trailing_slash}" -eq "${YES}" ] && windows_path="$( remove_trailing_slash --str "${windows_path}" )"

  typeset line=
  while read -r line
  do
    printf "%s\n" "${line}" | \grep -q "${windows_path}"
    if [ $? -eq "${PASS}" ]
    then
      typeset matched_directory=
      if [ "x${style}" == "xreverse" ]
      then
	      matched_directory=$( remove_whitespace --data "$( print_plain \"${line}\" | \cut -c 11-36 )" )
      else
	      printf "%s\n" "${line}" | \grep -q "OK"
	      if [ $? -eq "${PASS}" ]
        then
          matched_directory="$( print_plain --message "${line}" | \cut -c 14 )"
	      else
          printf "%s\n" "${line}" | \grep -q "Disconnected"
          if [ $? -eq "${PASS}" ]
	        then
	         matched_directory="$( print_plain --message "${line}" | \cut -c 14 )"
          else
	         matched_directory="$( print_plain --message "${line}" | \cut -c 1 )"
	        fi
	      fi
      fi
      print_plain --message "${matched_directory}"
      break
    fi
  done < "${tmpfile}"

  [ -f "${tmpfile}" ] && \rm -f "${tmpfile}"
  return "${PASS}"
}

relative_to_absolute()
{
  __debug $@
  
  typeset relpath=
  
  OPTIND=1
  while getoptex "p. path." "$@"
  do
    case "${OPTOPT}" in
    'p'|'path' ) relpath="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${relpath}" )" -eq "${YES}" ] && return "${FAIL}"
  if [ "${relpath:(1)}" != "/" ]
  then
    print_plain --message "${relpath}"
    return "${PASS}"
  fi
  
  typeset ABS=
  [ "x${PWD}" != "x/" ] && ABS="${PWD}"

  OLDIFS="${IFS}"
  IFS="/"
  typeset DIR=
  for DIR in ${relpath}
  do
    if [ "$( is_empty --str "${DIR}" )" -eq "${NO}" ]
    then
      if [ "${DIR}" == ".." ]
      then
        ABS="${ABS%/*}"
      elif [ "${DIR}" != "." ]
      then
        ABS="${ABS}/${DIR}"
      fi
    fi
  done
  IFS="${OLDIFS}"

  [ "$( is_empty "${ABS}" )" -eq "${NO}" ] && print_plain --message "${ABS}"
  return "${PASS}" 
}

relative_path()
{
  __debug $@
  
  typeset from='.'
  typeset to='.'

  OPTIND=1
  while getoptex "f. from. t. to." "$@"
  do
    case "${OPTOPT}" in
    'f'|'from' ) from="${OPTARG}";;
    't'|'to'   ) to="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "${from}" == "${to}" ]
  then
    print_plain --message '.'
    return "${PASS}"
  fi

  #shopt -s extglob

  from2=$( \readlink -f "${from}" )
  to2=$( \readlink -f "${to}" )

  typeset original_path="${from}"

  from=${from2%/}
  to=${to2%/}

  from="${from}/"
  to="${to}/"

  typeset part1=
  while true
  do
    [ $( is_empty --str "${from}" ) -eq "${YES}" ] && break

    part1="${to#${from}}"
    if [ "${part1#/}" == "${part1}" ]
    then
      to="${to%/*}"
      continue
    fi

    if [ "${to#${from}}" == "${to}" ]
    then
      from="${from%/*}"
      continue
    fi

    break
  done

  part1="${from}"
  from="${original_path#${part1}}"

  typeset depth="${from//+([^\/])/..}"

  from="${to#${from}}"
  from="${depth}${to#${part1}}"
  from="${from##+(\/)}"
  from="${from%/}"

  [ "$( is_empty --str "${from}" )" -eq "${YES}" ] && from='.'

  print_plain --message "${from}"
  return "${PASS}"
}

remove_mount_points()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"
	
  cd "${HOME}" > /dev/null 2>&1 || return "${FAIL}"

  typeset added_driveletters="$( hget --map "add_drivemaps" --key "created" )"
  typeset dl=
  for dl in ${added_driveletters}
  do
    unmap_network_drive --path "${dl}"
  done
  return "${PASS}"
  
  cd "-" > /dev/null 2>&1 || return "${FAIL}"
  return "${PASS}"
}

rotate_file()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset filename=
  typeset startpt=0
  typeset maxlines="${__MAXIMUM_LOGFILE_LINES}"
  
  OPTIND=1
  while getoptex "f: file: s: start-pt: m: maximum-lines:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'           )   filename="${OPTARG}";;
    's'|'start-pt'       )   startpt="${OPTARG}";;
    'm'|'maximum-lines'  )   maxlines="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ ! -f "${file}" ] && return "${FAIL}"

  # Need to verify input is of correct type and represents
  # a logical range available.  If the maximum number of
  # lines is 0, then NO log rotation is performed.
  [ "$( is_numeric_data --data "${maxlines}" )" -eq "${NO}" ] && maxlines="${__MAXIMUM_LOGFILE_LINES}"
  [ "${maxlines}" -lt 0 ] && maxlines="${__MAXIMUM_LOGFILE_LINES}"
  [ "${maxlines}" -eq 0 ] && return "${PASS}"

  typeset currentlines=0

  (( startpt = currentlines - maxlines + 1 ))

  [ "${startpt}" -le 0 ] && return "${PASS}"

  # Make a temporary file of the logfile to rotate
  # Caveat is that the original file is NOT locked
  # from further writing whilst this operation is
  # performed!!!
  typeset tmpfile="$( make_temp_file )"
  typeset idx=0

  typeset line=
  while read -u 9 -r line
  do
    idx=$( increment "${idx}" )
    [ "${idx}" -ge "${startpt}" ] || [ "$( find_match_in_line --line "${line}" --pattern "HEADER" )" -eq ${YES} ] && print_plain --message "${line}" >> "${tmpfile}"
  done 9< "${file}"
  [ -f "${tmpfile}" ] && \mv -f "${tmpfile}" "${file}"
  return ${PASS}
}

timed_rotation_of_file()
{
  __debug $@

  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  typeset file=
  typeset interval_time=$2
  typeset last_check=$3

  OPTIND=1
  while getoptex "f: file: i: interval: c: last-check:" "$@"
  do
    case "${OPTOPT}" in
    'f'|'file'       ) file="${OPTARG}";;
    'i'|'interval'   ) interval_time="${OPTARG}";;
    'c'|'last-check' ) last_check="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ ! -f "${file}" ] && return "${FAIL}"
  
  typeset current_time="$( date "+s%" )"
  typeset delta_time=0
  (( delta_time = current_time - last_check ))

  if [ "${delta_time}" -gt "${interval_time}" ]
  then
    typeset max_lines="$( hget --map "logfile_parameters_teefile" --key "maxlines" )"
    typeset current_number_of_lines="$( __unix_prefix_trim "$( \wc -l "${file}" )" ) | \cut -f 1 -d ' '"
    [ "${current_number_of_lines}" -gt "${max_lines}" ] && rotate_file --file "${file}" --start-pt "${current_number_of_lines}" --maximum-lines "${max_lines}"
  fi
    
  print_plain --message "${current_time}"
  return "${PASS}"
}

unmap_network_drive()
{
  __debug $@
  
  __ensure_local_machine_identified
  typeset RC=$?
  [ "${RC}" -ne "${PASS}" ] && return "${FAIL}"

  [ "$( is_windows_machine )" -eq "${NO}" ] && return "${FAIL}"

  OPTIND=1
  while getoptex "d. drive-letter." "$@"
  do
    case "${OPTOPT}" in
    'd'|'drive-letter' ) drive_letter="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${drive_letter}" )" -eq "${YES}" ] && return "${FAIL}"

  typeset cmd="net use /DELETE ${drive_letter}: > /dev/null 2>&1"
  eval "${cmd}"
  return $?
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | \grep -q 'is a function'
if [ $? -ne 0 ]
then
  # shellcheck source=/dev/null
  . "${SLCF_SHELL_TOP}/lib/base_machinemgt.sh"
fi
__initialize_machinemgt
__prepared_machinemgt
