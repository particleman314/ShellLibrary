#!/usr/bin/env bash

defval=$( default_value --def 2 1 )
assert 1 ${defval}

defval=$( default_value --def 2 '' )
assert 2 ${defval}
