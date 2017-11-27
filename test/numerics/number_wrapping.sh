#!/bin/sh

max=5

assert 1 $( number_wrapping --data 1 --wrap ${max} )
assert 4 $( number_wrapping --data 4 --wrap ${max} )
assert 2 $( number_wrapping --data 7 --wrap ${max} )
assert 0 $( number_wrapping )
