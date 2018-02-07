#!/usr/bin/env bash

max=4
for i in $( seq 1 ${max} )
do
  spinner -s 500000 --counter ${max}
done

printf "\n"
