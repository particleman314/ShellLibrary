#!/bin/sh

external_file_manipulation()
{
  typeset tempdir="${SUBSYSTEM_TEMPORARY_DIR}"
  typeset subdir='filemgt'

  \mkdir -p "${tempdir}/${subdir}"
  TEST_FILE1="${tempdir}/${subdir}/sample_file.txt"
  TEST_FILE2="${tempdir}/${subdir}/sample_file"

  touch "${TEST_FILE1}"
  touch "${TEST_FILE2}"

  schedule_for_demolition "${tempdir}/${subdir}"
}

internal_file_manipulation()
{
  typeset tempdir="${SUBSYSTEM_TEMPORARY_DIR}"
  typeset subdir='filemgt'

  \mkdir -p "${tempdir}/${subdir}"
  TEST_FILE="${tempdir}/${subdir}/sample_file.txt"

  touch "${TEST_FILE}"
  printf "%s\n" "This is a sample file used for internal testing" >> "${TEST_FILE}"
  printf "%s\n" "It has a myriad of settings..." >> "${TEST_FILE}"
  printf "%s\n" "   1\) Has a list" >> "${TEST_FILE}"
  printf "%s\n" "   2\) Says 'Hello World'" >> "${TEST_FILE}"
  printf "%s\n" "   3\) Is used by the filemgt testing architecture" >> "${TEST_FILE}"

  schedule_for_demolition "${tempdir}/${subdir}"
}

case "$1" in
'internal' ) internal_file_manipulation;;
'external' ) external_file_manipulation;;
esac

