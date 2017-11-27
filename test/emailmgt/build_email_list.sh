#!/bin/sh

answer=$( build_email_list )
assert_success $?
assert_not_empty "${answer}"
assert_comparison --comparison '=' $( count_items --data "${answer}" ) 2

answer=$( build_email_list --email blah )
assert_success $?
assert_comparison --comparison '=' $( count_items --data "${answer}" ) 3

answer=$( build_email_list --email blah2 --company 'ca.com' )
assert_success $?
assert_comparison --comparison '=' $( count_items --data "${answer}" ) 3
detail "${answer}"