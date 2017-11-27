##
## Broken Hello World for Python
##
## Expected Result: 1
##
import os

prefix="\t"

if 'SLCF_DETAIL' in os.env:
    if os.env['SLCF_DETAIL'] != 0:
        prefix=os.env['SLCF_PREFIX_DETAIL']
    
print(prefix+"\tHello World.  Running Python from the Shell Test Harness ( part of the Shell Library Component Framework )")
