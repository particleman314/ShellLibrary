#!/usr/bin/env bash

libname="$1"
[ -z "${libname}" ] && exit 1

infopath="$2"
[ -z "${infopath}" ] && infopath='.'
[ ! -d "${infopath}" ] && exit 1

libdir="$3"
[ -z "${libdir}" ] || [ ! -d "${libdir}" ] && exit 1

libname_cap="$( \tr [:lower:] [:upper:] <<< ${libname:0:1} )${libname:1}"
printf "%s\n" "Building INFO file for ${libname_cap} library..."

infofile="${infopath}/INFO_${libname_cap}.md"

\rm -f "${infofile}"

details="$( \cat "${libdir}/${libname}.sh" | \grep '^## @' | \grep -v 'fn' )"
methods="$( \cat "${libdir}/${libname}.sh" | \grep -i '()' | \grep -v '@fn' )"

printf "# %s\n\n" "Information for << ${libname_cap} >> Library" >> "${infofile}"
OLDIFS="${IFS}"
IFS=$'\n'
for dt in ${details}
do
  dtattr="$( printf "%s\n" "${dt}" | \cut -f 1 -d ':' | \sed -e 's/^[[:blank:]]*//g' -e 's/[[:blank:]]*$//g' -e "s/$( printf "\t" )//g" | \cut -c 5- )"
  if [ "${dtattr}" == 'Author' ] || [ "${dtattr}" == 'Version' ]
  then
    dtdata="$( printf "%s\n" "${dt}" | \cut -f 2 -d ':' | \sed -e 's/^[[:blank:]]*//g' -e 's/[[:blank:]]*$//g' )"
    printf "* %s --> %s\n" "${dtattr}" "${dtdata}" >> "${infofile}"
  fi
done
IFS="${OLDIFS}"

printf "\n# %s\n\n" "Known Methods" >> "${infofile}"
for mn in ${methods}
do
  mn="$( printf "%s\n" "${mn}" | \tr '(' ' ' | \tr ')' ' ' | \sed -e 's/[[:blank:]]*//g' )"
  printf "* %s\n" "\`${mn}\`" >> "${infofile}"
done

\cat "${infofile}"