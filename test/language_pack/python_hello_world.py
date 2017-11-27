##
## Hello World for Python
##
import os
import sys

prefix="\t"

if 'SLCF_DETAIL' in os.environ:
    if os.environ['SLCF_DETAIL'] != 0:
        prefix=os.environ['SLCF_PREFIX_DETAIL']
    
print(prefix+"  Hello World.  Running Python from the Shell Test Harness ( part of the Shell Library Component Framework )")
print(prefix+"  Arguments were : "+' '.join(sys.argv[1:]))
