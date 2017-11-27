#!/bin/sh

detail "Starting test for method : $1"

pkgdir="${SLCF_SHELL_RESOURCEDIR}/Linux"
if [ -d "${pkgdir}" ]
then
  assert_true 1
else
  assert_true 0
fi

machine_classification=$( which_linux_variety_to_use )
assert_not_empty "${machine_classification}"

pkgfile="${pkgdir}/${machine_classification}.pgs"
if [ -f "${pkgfile}" ]
then
  assert_true 1
else
  assert_true 0
fi

__use_resource "${pkgfile}"
assert_success $?
assert_true "${__SETUP_PKG}"

__use_resource "${SLCF_SHELL_RESOURCEDIR}/Linux/scientific_linux.pgs"
assert_failure $?

detail "Ending test for method : $1"
