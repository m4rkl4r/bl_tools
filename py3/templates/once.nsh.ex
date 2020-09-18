#!/bin/bash

#### START preamble
echo "starting vas_domain_decom_check.nsh"
## initially created 2019-07-17 by Mark Price
LANE="$1"
LOGDIR="$2"
LOG="$3".`date -I`
DOMAIN="$4"
HOSTS="$5"
HEADERGRP="/WorkAreas/ENG_ROLE/headers/setup.sh"
HEADERFILE="setup.1.sh"

DATE=`date +%Y%m%d_%H`

export LOGHOST LOGDIR HEADERGRP
## source setup.sh and prove it
FILE=
COUNT=0
short=`echo $NSH_RUNCMD_HOST | cut -f1 -d.`
while test -z "$FILE"; do
    echo "looking up $HEADERFILE"
    FILE=`blcli_execute DepotObject getFullyResolvedPropertyValue DEPOT_FILE_OBJECT "$HEADERGRP" "$HEADERFILE" LOCATION\*`
    if test -z "$FILE";
    then
            COUNT=$((COUNT+1))
            sleep 5
    else
            echo "Found setup.sh FILE=$FILE; `ls -l $FILE`"
    fi
    echo COUNT=$COUNT
    if test $COUNT = 5; then
            echo "couldnt find $HEADERFILE.  Exiting"
            exit 99
    fi
done
source $FILE
h_prefix echo "$FILE sourced"


## startup, in part, initialize logging, setting "$LOGBASE" and "$LOGFILE" for future use
## LOGBASE is //$LOGHOST/$LOGDIR; $LOGFILE is $LOGBASE/$LOG
startup "$LANE" "$LOGDIR" "$LOG"

### END preamble

## check whether vasd is connected to $domain, then check the config files
for fqdn in $HOSTS
do
    h_prefix echo "========= START ON $fqdn ========="
    if ! once_setup_host $fqdn; then
        echo "$fqdn: could not cd there"
        continue;
    fi


    ##### this runs the command as root on host $fqdn, and prepends $fqdn's short name to all output
    #echo "==== START $SHORT: vastool inspect vasd cross-forest-domain ===="
    #h_prefix n_exec /opt/quest/bin/vastool inspect vasd cross-forest-domain | egrep -i "$DOMAIN"
    #INSPECT_ERR=$?

    ##### this runs the command as bladmon on host $fqdn, and prepends $fqdn's short name to all output
    #if [ "$ENSPECT_ERR" = 0 ]; then
    #    h_prefix echo "$domain found in vastool inspect vasd cross-forest-domain"

    once_teardown_host $fqdn
    h_prefix echo "========= END ON $fqdn ========="
done | tee -a "$LOGFILE"
