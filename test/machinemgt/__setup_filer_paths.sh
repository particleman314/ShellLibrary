#!/usr/bin/env bash

FILER_FILE="${SLCF_SHELL_TOP}/test/machinemgt/filer.txt"

touch "${FILER_FILE}"
printf "%s\n" "C:/Temp|/tmp" >> "${FILER_FILE}"
