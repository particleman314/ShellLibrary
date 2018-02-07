#!/usr/bin/env bash

assert 0 $( decrement 1 1 )
assert 0 $( decrement 1 )
assert 2 $( decrement 5 3 )

assert 8 $( decrement 5 -3 )
