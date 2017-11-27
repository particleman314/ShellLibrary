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
## @Software Package : Shell Automated Testing -- Process Management
## @Application      : Support Functionality
## @Language         : Bourne Shell
## @Version          : 1.02
#
###############################################################################

###############################################################################
#
# Functions Supplied:
#
#    __pids_var_run
#    __pids_pidof
#    add_pid
#    checkpid
#    count_processes
#    daemon
#    get_pid_file_location_dir
#    get_pid_id_location_dir
#    get_pid_lockfile_dir
#    get_pid_file_extension
#    enable_corefiles
#    find_process
#    kill_process
#    pidfile_of_process
#    pid_of_process
#    set_pid_file_location_dir
#    set_pid_id_location_dir
#    set_pid_lockfile_dir
#    set_pid_file_extension
#    status
#    wait_pids
#
###############################################################################

# shellcheck disable=SC2016

declare -a __PIDS

# This may be OS platform dependent
if [ -z "${__PID_ID_LOCATION_DIR}" ]
then
  __PID_ID_LOCATION_DIR='/proc'
  __PID_FILE_LOCATION_DIR='/var/run'
  __PID_LOCKFILE_DIR='var/lock/subsys'
  __PID_EXTENSION='.pid'
  __PID_MAP='pid_map'
fi

__initialize_processmgt()
{
  [ -z "${SLCF_SHELL_TOP}" ] && SLCF_SHELL_TOP=$( \readlink -f "$( \dirname '$0' )" )

  __load __initialize_paramfilemgt "${SLCF_SHELL_TOP}/lib/paramfilemgt.sh"
  __load __initialize_logging "${SLCF_SHELL_TOP}/lib/logging.sh"

  load_parameter_file --file "${SLCF_SHELL_TOP}/resources/common/process_codes.txt" --suppress

  __initialize "__initialize_processmgt"
}

__pids_pidof()
{
   [ $# -lt 1 ] && return "${FAIL}"
   [ -z "${pidof_exe}" ] && make_executable --exe 'pidof'
   if [ -n "${pidof_exe}" ] && [ -x "${pidof_exe}" ]
   then
     typeset addon_options=' -c'
     typeset cmd="${pidof_exe} -o $$ -o $PPID -o \%PPID -x"
     eval "${cmd} \"$1\" 2>&1 >/dev/null"
     if [ $? -ne 0 ]
     then
       eval "${cmd} \"${1##*/}\" 2>&1 >/dev/null"
     fi
     if [ $? -ne 0 ]
     then
       cmd+="${addon_options}"  
       eval "${cmd} \"$1\" 2>&1 >/dev/null"
     fi
     if [ $? -ne 0 ]
     then
       eval "${cmd} \"${1##*/}\" 2>&1 >/dev/null"
     fi
    
     return $?
   fi
   return "${FAIL}"
}

__pids_var_run() 
{
  __debug $@

  typeset base=
  typeset pid_file=
  
  OPTIND=1
  while getoptex "b: base: p: pid-file:" "$@"
  do
    case "${OPTOPT}" in
    'b'|'base'    ) base="${OPTARG}";;
    'p'|'pid-file') pid_file="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  base=${base##*/}
  [ -z "${base}" ] && return "${NOT_ENOUGH_INFORMATION}"

  [ "$( is_empty --str "${pid_file}" )" -eq "${YES}" ] && pid_file="${__PID_FILE_LOCATION_DIR}/${base}.${__PID_EXTENSION}"

  typeset pid=
  if [ -f "${pid_file}" ]
  then
    typeset line
    typeset p

    [ ! -r "${pid_file}" ] && return "${INSUFFICIENT_PRIVILEGE}" # "user had insufficient privilege"
    while read -r -u 9 line
    do
      [ "$( is_empty --str "${line}" )" -eq "${YES}" ] && break
      for p in ${line}
      do
        [ "$( is_empty --str "${p//[0-9]/}" )" -eq "${YES}" ] && [ -d "${__PID_ID_LOCATION_DIR}/$p" ] && pid="${pid} ${p}"
      done
    done 9< "${pid_file}"

    [ "$( is_empty --str "${pid}" )" -eq "${NO}" ] && return "${NORMAL_TERMINATION}"
    return "${PROGRAM_DEAD}" # "Program is dead and ${__PID_FILE_LOCATION_DIR} pid file exists"
  fi
  return "${PROGRAM_NOT_RUNNING}" # "Program is not running"
}

__prepared_processmgt()
{
  __prepared "__prepared_processmgt"
}

add_pid() 
{
  __debug $@
  
  typeset desc=
  typeset pid=
  
  OPTIND=1
  while getoptex "d: description: p: pid:" "$@"
  do
    case "${OPTOPT}" in
    'd'|'description'  )  desc="${OPTARG}";;
    'p'|'pid'          )  pid="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${pid}" ] && return "${FAIL}"

  hadd_item --map "${__PID_MAP}" --key "${pid}" --value "${desc}"
  return "${PASS}"
}

checkpid() 
{
  typeset i=
  
  if [ "$( is_windows_machine )" -eq "${NO}" ]
  then
    for i in $@
    do
      [ -d "${__PID_ID_LOCATION_DIR}/$i" ] && return "${PASS}"
    done
    return "${FAIL}"
  else
    return "${FAIL}"
  fi
}

count_processes()
{
  __debug $@

  typeset process_idtype=

  OPTIND=1
  while getoptex "p: pidtype:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pidtype' ) process_idtype="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${process_idtype}" )" -eq "${YES}" ]
  then
    print_plain --message "0" --format "%d"
    return "${FAIL}"
  fi

  # This will need to be special cased for differing operating systems

  typeset result="$( \ps -eaf | \grep "${process_idtype}" | \grep -cv grep )"
  print_plain --message "${result}" --format "%d"
  return "${PASS}"
}

daemon() 
{
  __debug $@
  
  typeset gotbase=
  typeset force="${NO}"
  typeset nicelevel=0
  typeset pid base=
  typeset user=
  typeset nice=
  typeset bg=
  typeset pid_file=
  typeset cgroup=
  typeset user_nice="${NO}"

  OPTIND=1
  while getoptex "c: check: u: user: p: pidfile: f. force. n. nice." "$@"
  do
    case "${OPTOPT}" in
    'c'|'check'     )   base="${OPTARG}"; gotbase="${YES}";;
    'u'|'user'      )   user="${OPTARG}";;
    'p'|'pidfile'   )   pid_file="${OPTARG}";;
    'f'|'force'     )   force=${YES};;
    'n'|'nice'      )   nicelevel="${OPTARG}"; nice="nice -n ${nicelevel}"; user_nice="${YES}";;
    * )                 return "${FAIL}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "${gotbase}" -eq "${NO}" ] && base="$( \basename ${base} )"
  
  __pids_var_run --base "${base}" --pid-file "${pid_file}"

  [ "$( is_empty --str "${pid}" )" -eq "${NO}" ] && [ "${force}" -eq "${NO}" ] && return "${PASS}"

  typeset corelimit="ulimit -S -c ${DAEMON_COREFILE_LIMIT:-0}"

  [ "${user_nice}" -eq "${NO}" ] && [ "$( is_empty --str "${NICELEVEL:-}" )" -eq "${NO}" ] && nice="nice -n ${NICELEVEL}"

  if [ "$( is_empty --str "${CGROUP_DAEMON}" )" -eq "${NO}" ]
  then
    if [ ! -x "$( \which cgexec 2>/dev/null )" ]
    then
      print_plain --message "cgroups not installed"
    else
      cgroup='cgexec';
      for i in ${CGROUP_DAEMON}
      do
	cgroup="${cgroup} -g ${i}";
      done
    fi
  fi

  typeset RC=
  if [ "$( is_empty --str "${user}" )" -eq "${YES}" ]
  then
    ${cgroup} ${nice} ${SHELL} -c "${corelimit} >/dev/null 2>&1 ; $*"
    RC=$?
  else
    ${cgroup} ${nice} runuser -s ${SHELL} ${user} -c "${corelimit} >/dev/null 2>&1 ; $*"
    RC=$?
  fi
  
  if [ "${RC}" -eq "${PASS}" ]
  then
    print_std_success --message "${base}"
  else
    print_std_failure --message "${base}"
  fi

  return "${RC}"
}

enable_corefiles()
{
  __debug $@
  
  typeset coreloc=${1:-/cores}

  OPTIND=1
  while getoptex "c: core-location:" "$@"
  do
    case "${OPTOPT}" in
    'c'|'core-location') coreloc="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  # Check OSVARIETY
  typeset LINUX_DISTRO=
  typeset RC=

  [ "${ostype}" == "linux" ] && LINUX_DISTRO="$( get_linux_variety )"

  case "${OSVARIETY}" in
    'aix' )
      if [ ! -e "${coreloc}" ]
      then
        \mkdir -p "${coreloc}"
        \chmod 1777 "${coreloc}"
      fi
      \chdev -l sys0 -a fullcore='true' -a pre430core='false'
      \chcore -d -p on -n on -l "${coreloc}"
      \syscorepath -p "${coreloc}"
      ;;

    'hp' )
      if [ ! -e "${coreloc}" ]
      then
        \mkdir -p "${coreloc}"
        \chmod 1777 "${coreloc}"
      fi
      \coreadm -g "${coreloc}"/%f.%n.%p.%t.core -e global 
      ;;

    'linux' )
      case "${linux_distro}" in
        'redhat' )
          if [ ! -e "${coreloc}" ]
	  then
            \mkdir -p "${coreloc}"
            \chmod  1777 "${coreloc}"
          fi
    
          \grep -q "fs.suid_dumpable = 2" /etc/sysctl.conf
	  RC=$?
          if [ "${RC}" -eq "${FAIL}" ]
	  then
	    printf "%s\n" "fs.suid_dumpable = 2" >> /etc/sysctl.conf
	  else
	    convert_pattern --file "/etc/sysctl.conf" --old-patt '^fs.suid_dumpable.*' --new-patt 'fs.suid_dumpable = 2'
	  fi
    
          \grep -q 'kernel.core_pattern' /etc/sysctl.conf
	  RC=$?
          if [ "${RC}" -eq "${FAIL}" ]
	  then
	    printf "%s\n" "kernel.core_pattern = ${coreloc}/%e_%h_%u_%g_%t_%p.core" >> /etc/sysctl.conf
	  else
	    convert_pattern --file '/etc/sysctl.conf' --old-patt '^kernel.core_pattern.*' --new-patt "kernel.core_pattern = ${coreloc}/%e_%h_%u_%g_%t_%p.core"
          fi
          \sysctl -p
	  \ulimit -c unlimited
          ;;
    
        'suse' )
          \install -m 1777 -d "${coreloc}"
          printf "%s\n" "${coreloc}/%e_%h_%u_%g_%t_%p.core" > /proc/sys/kernel/core_pattern
          # Need to check to see if this application exists
          \rcapparmor stop
          \sysctl -w kernel.suid_dumpable=2
          ;;
    
        * )
          print_msg -m "$0 does not know how to enable cores on ${OSVARIETY} ${LINUX_DISTRO}, exiting" -t ERROR --fullscreen
          return "${FAIL}"
          ;;
      esac
	  ;;

    'solaris' )
      if [ ! -e "${coreloc}" ]
      then
        \mkdir -p "${coreloc}"
        \chmod 1777 "${coreloc}"
      fi
      \coreadm -g "${coreloc}"/%f.%n.%p.%t.core -e global -e global-setid -e log -d process -d proc-setid
      ;;

    * )
      print_msg -m "enable_corefiles does not know how to enable cores on ${OSVARIETY}, exiting" -t ERROR --fullscreen
      return "${FAIL}"
      ;;
  esac
  return "${PASS}"
}

find_process()
{
  __debug $@
  
  typeset process_name=
  
  OPTIND=1
  while getoptex "p: process-id:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'process-id' ) process_name="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ "$( is_empty --str "${process_name}" )" -eq "${YES}" ]
  then
    print_plain --message "${NO}"
    return ${FAIL}
  else
    # This needs to be made os specific and second grep may always succeed causing $? to be always true
    typeset procmatch="$( \ps -eaf | \grep -E "${process_name}\\b" | \grep -v \grep )"
    typeset RC=$?
    if [ "${RC}" -eq "${PASS}" ]
    then
      print_plain --message "${YES}"
    else
      print_plain --message "${NO}"
    fi
  fi
  return "${PASS}"
}

kill_process()
{
  __debug $@
  
  typeset rc=0
  typeset kill_level=
  typeset base=
  typeset pid=
  typeset pid_file=
  typeset delay=3
  typeset try=0
  
  OPTIND=1
  while getoptex "p: pid-file: d. delay. s. kill-level. program:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pid-file'   ) pid_file="${OPTARG}";;
    'd'|'delay'      ) delay="${OPTARG}";;
    's'|'kill-level' ) kill_level="${OPTARG}";;
	'program'    ) base="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  if [ "$( is_empty --str "${pid_file}" )" -eq "${YES}" ] || [ ! -f "${pid_file}" ]
  then
    print_plain --message "Usage: kill_process [ --program program ] [ -p pidfile ] { -s signal } { -d delay }"
    return ${FAIL}
  fi
  
  [ "${delay}" -lt 0 ] && delay=3  
  base="${base##*/}"

  __pids_var_run --base "${base}" --pid-file "${pid_file}"
  RC=$?
  
  if [ "$( is_empty --str "${pid}" )" -eq "${YES}" ]
  then
    if [ "$( is_empty --str "${pid_file}" )" -eq "${YES}" ]
    then
      pid="$(__pids_pidof "${base}")"
    else
      if [ "${RC}" -eq "${INSUFFICIENT_PRIVILEGES}" ]
      then
	print_std_failure --message "${base} shutdown"
	return "${RC}"
      fi
    fi
  fi
  
  if [ "$( is_empty --str "${pid}" )" -eq "${NO}" ]
  then
    if [ "$( is_empty --str "${kill_level}" )" -eq "${YES}" ]
    then
      if \checkpid "${pid}" 2>&1
      then
        \kill -TERM "${pid}" >/dev/null 2>&1
	sleep_func -s 50000
        if \checkpid "${pid}"
        then
          #try=0
          while [ ${try} -lt ${delay} ]
          do
            \checkpid "${pid}" || break
            sleep_func -s 1 --old-version
            try="$( increment ${try} )"
          done
          if \checkpid "${pid}"
          then
            \kill -KILL "${pid}" >/dev/null 2>&1
	    sleep_func -s 50000
          fi
        fi
      fi
      \checkpid "${pid}"
      RC=$?
      if [ "${RC}" -eq "${PASS}" ]
      then
	print_std_failure --message "${base} shutdown"
      else
	print_std_success --message "${base} shutdown"
      fi
      RC=$(( ! ${RC} ))
    else
      if \checkpid "${pid}"
      then
        kill -${kill_level} "${pid}" >/dev/null 2>&1
        RC=$?
        if [ "${RC}" -eq "${PASS}" ]
	then
	  print_std_success --message "${base} shutdown"
        else
	  print_std_failure --message "${base} shutdown"
	fi
      fi
    fi
  else
    if [ $( is_empty --str "${killlevel}" ) -eq "${NO}" ]
    then
      RC="${PROGRAM_NOT_RUNNING}" # Program is not running
    else
      print_std_failure --message "${base} shutdown"
      RC="${NORMAL_TERMINATION}"
    fi
  fi
  
  [ "$( is_empty --str "${kill_level}" )" -eq "${YES}" ] && \rm -f "${pid_file:-${__PID_FILE_LOCATION_DIR}/${base}.pid}"
  return ${RC}
}

pidfile_of_process()
{
  __debug $@
  
  typeset pid=

  [ $# -eq 0 ] && return "${FAIL}"

  OPTIND=1
  while getoptex "b: base:" "$@"
  do
    case "${OPTOPT}" in
    'b'|'base' ) base="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ -z "${base}" ] && return "${FAIL}"

  pid="$( __pids_var_run --base "${base}" )"
  [ "$( is_empty --str "${pid}" )" -eq "${NO}" ] && print_plain --message "${pid}" --format "%d"
  return "${PASS}"
}

pid_of_process()
{
  __debug $@
  
  typeset pid_file=

  [ $# -eq 0 ] && return "${FAIL}"

  OPTIND=1
  while getoptex "b: base: p: pid-file:" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pid-file' ) pid_file="${OPTARG}";;
    'b'|'base'     ) base="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))
  
  # First try "${__PID_FILE_LOCATION_DIR}/*.pid" files
  typeset pid="$( __pids_var_run --base "${base}" --pid-file "${pid_file}" )"
  typeset RC=$?
  
  [ "$( is_empty --str "${pid_file}" )" -eq "${NO}" ] && return "${RC}"
  __pids_pidof --base "${base}" || return "${RC}"
}

status()
{
  __debug $@

  typeset program=
  typeset pid=
  typeset lock_file=
  typeset pid_file=

  [ $# -eq 0 ] && return "${FAIL}"

  OPTIND=1
  while getoptex "program: p: pid-file: l: lock-file:" "$@"
  do
    case "${OPTOPT}" in
    'l'|'lock-file' ) lock_file="${OPTARG}";;
    'p'|'pid-file'  ) pid_file="${OPTARG}";;
	'program'   ) program="${OPTARG}";;
    esac
  done
  shift $(( OPTIND-1 ))

  if [ -z "${program}" ]
  then
    print_msg --message 'Program name not provided'
    return "${FAIL}"
  fi

  typeset base="${program##*/}"

  __pids_var_run "${program}" "${pid_file}"
  typeset RC=$?
  [ "$( is_empty --str "${pid_file}" )" -eq "${YES}" ] && [ "$( is_empty --str "${pid}")" -eq "${YES}" ] && pid="$( __pids_pidof "${program}" )"
  if [ "$( is_empty --str "${pid}" )" -eq "${NO}" ]
  then
    print_plain --message "${base} [ pid(s) -- ${pid} ] is/are running..."
    return "${PASS}"
  fi

  case "${RC}" in
  "${NORMAL_TERMINATION}" )
    print_plain --message "${base} [ pid(s) -- ${pid} ] is/are running..."
    return ${RC}
    ;;
  "${PROGRAM_DEAD}" )
    print_plain --message "${base} dead but pid file exists"
    return ${RC}
    ;;
  "${INSUFFICIENT_PRIVILEGES}" )
    print_plain --message "${base} status unknown due to insufficient privileges."
    return ${RC}
    ;;
  esac
  
  [ "$( is_empty --str "${lock_file}" )" -eq "${YES}" ] && lock_file="${base}"

  if [ -f "${__PID_LOCKFILE_DIR}/${lock_file}" ]
  then
    print_plain --message "${base} dead but subsys locked"
    return "${PROGRAM_DEAD_WITH_LOCKED}"
  fi
  
  print_plain --message "${base} is stopped"
  return "${PROGRAM_NOT_RUNNING}"
}

wait_pids() 
{
  __debug $@

  typeset pids=
  typeset suppress="${NO}"
  
  OPTIND=1
  while getoptex "p: pid: s suppress" "$@"
  do
    case "${OPTOPT}" in
    'p'|'pid'      ) pids+="${OPTARG} ";;
    's'|'suppress' ) suppress="${YES}";;
    esac
  done
  shift $(( OPTIND-1 ))

  [ "$( is_empty --str "${pids}" )" -eq "${YES}" ] && return "${PASS}"

  typeset p
  for p in ${pids}
  do
    [ "$( is_numeric_data --data "${p}" )" -eq "${NO}" ] && continue 
    hadd_item --map 'pid_map_kill' --key "${p}" --value '1'
  done

  typeset RC
  while [ 1 == 1 ]
  do
    pids="$( hkeys --map 'pid_map_kill' )"
    [ "$( is_empty --str "${pids}" )" -eq "${YES}" ] && break
    [ "${suppress}" -eq "${NO}" ] && print_plain --message "Waiting for pid(s) --> ${pids}"

    for p in ${pids}
    do
      \kill -0 "${p}" 2>/dev/null
      RC=$?
      [ "${RC}" -ne "${PASS}" ] && hdel --map 'pid_map_kill' --key "${p}"
    done
    sleep_func -s 1 --old-version
  done

  hclear --map 'pid_map_kill'

  return "${PASS}"
}

# ---------------------------------------------------------------------------
type "__initialize" 2>/dev/null | grep -q 'is a function'
if [ $? -ne 0 ]
then
  . "${SLCF_SHELL_TOP}/lib/paramfilemgt.sh"
  . "${SLCF_SHELL_TOP}/lib/logging.sh"
fi

__initialize_processmgt
__prepared_processmgt
