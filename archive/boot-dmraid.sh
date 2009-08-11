#!/bin/bash
#%stage: block
#%depends: dm
#%provides: dmroot
#%programs: /sbin/dmraid
#%if: -n "$root_dmraid"
#
##### Device Mapper Raid
##
## If the root device uses a software raid based on device mapper, 
## this initializes and waits for the device to appear.
##
## Command line parameters
## -----------------------
##
## root_dmraid=1	use device mapper raid
## 

/sbin/dmraid -a y -p
wait_for_events
