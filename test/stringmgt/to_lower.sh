#!/bin/sh

answer='hhhh'

trials='hhhh hHHh hhhH HHHH'

for t in ${trials}
do
  assert $( to_lower "${t}" ) "${answer}"
done

assert_empty $( to_lower '' )
