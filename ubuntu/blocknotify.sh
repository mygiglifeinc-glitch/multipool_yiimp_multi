#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Example blocknotify.sh for a daemon server that notifies several stratum
# servers: replace stratum_one etc. with the private IPs of your stratums.
#####################################################
blocknotify stratum_one:"$1" "$2" "$3"
blocknotify stratum_two:"$1" "$2" "$3"
blocknotify stratum_three:"$1" "$2" "$3"
