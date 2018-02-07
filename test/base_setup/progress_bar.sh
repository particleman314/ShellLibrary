#!/usr/bin/env bash

max=5
for i in $( seq 1 ${max} )
do
  progress_bar --current ${i} --total ${max}
  sleep_func -s 1 --old-version 
done

printf "\n"
