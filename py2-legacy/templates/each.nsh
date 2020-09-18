#!/bin/bash

## created by mark price in 2019
## 12/6/2019 - moved $short def next to $SHORT - mark price
#### START preamble
# initially created 2019-07-17 by Mark Price
LANE="$1"
LOGDIR="$2"
LOG="$3".`date -I`
NAMESERVERS="$4"
APPEND="$5"
HEADERGRP=[depot path to your header directory]
HEADERFILE=[your header file]

SHORT=`echo $NSH_RUNCMD_HOST|cut -f1 -d.`
short=`echo $NSH_RUNCMD_HOST | cut -f1 -d.`
DATE=`date +%Y%m%d_%H%M`

emulate sh

export LOGHOST LOGDIR HEADERGRP
## source setup.sh and prove it
FILE=
COUNT=0
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

## startup, in part, initialize logging, setting "$LOGBASE" and "$LOGFILE" for future use$$
## LOGBASE is //$LOGHOST/$LOGDIR; $LOGFILE is $LOGBASE/$LOG
startup "$LANE" "$LOGDIR" "$LOG"

### END preamble

assertLinux

(
    echo "========= $SHORT: STARTING WORK ========="
    echo "==== START $SHORT: cp /etc/resolv.conf /etc/resolv.conf.$DATE ===="
    #n_exec cp /etc/resolv.conf /etc/resolv.conf.$DATE
    #CP1_ERR=$?
    #if ! test "$CP1_ERR" = 0; then
    #    cleanup $CP1_ERR "could not back up resolv.conf"
    #fi
    echo "==== END $SHORT: cp /etc/resolv.conf /etc/resolv.conf.$DATE ===="
    echo "========= $SHORT: ENDING WORK ========="
) | tee -a "$LOGFILE"

STATUS=(${pipestatus[*]})
h_prefix echo "pipestats: ${STATUS[*]}"
CODE=${STATUS[0]}
if test "$CODE" = 0
then
    MESG="reolv.conf udpate succeeded"
else
    MESG="resolv.conf update failed"
fi
cleanup $CODE "$MESG"
