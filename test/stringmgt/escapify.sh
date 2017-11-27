#!/bin/sh

assert 'Hello' $( escapify 'Hello' )
assert '\\Hello' $( escapify '\Hello' )
assert 'C:\\Users\\ABC' $( escapify 'C:\Users\ABC' )
