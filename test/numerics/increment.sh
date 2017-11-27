#!/bin/sh

assert 2 $( increment 1 1 )
assert 2 $( increment 1 )
assert 10 $( increment 5 5 )

assert 2 $( increment 5 -3 )
