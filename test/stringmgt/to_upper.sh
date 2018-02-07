#!/usr/bin/env bash

answer='HHHH'

trials='hhhh hHHh hhhH HHHH'

for t in ${trials}
do
  assert $( to_upper "${t}" ) "${answer}"
done

assert_empty $( to_upper '' )
