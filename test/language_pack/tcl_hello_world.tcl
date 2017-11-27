##
## Hello World in Tcl
##

set prefix "\t"

if { [ array names ::env SLCF_DETAIL ] != "" } {
    if { $::env(SLCF_DETAIL) != 0 } {
        set prefix "$::env(SLCF_PREFIX_DETAIL)"
    }
}

puts "$prefix  Hello World.  Running Tcl from the Shell Test Harness ( part of the Shell Library Component Framework )"
