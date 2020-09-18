#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
COPY="$2"

function usage() {
        echo USAGE: $0 SCRIPT
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT"
        echo ""
        echo "SCRIPT should be in cwd and end with .N.sh or .N.nsh, where N is the version number."
        echo "SCRIPT must already exist before running this command."
        echo ""
        echo "This will mkdir ./params, ./hostlist, ./scripttype, ./parallelize"
        echo "and create parameter templates in ./params if they don't exist,"
        echo "and empty hostlist files in ./hostlist if they don't exist."
        echo ""
        echo "EXAMPLE: $0 demo.0.nsh"
        echo "In ./params, it will create templates called:"
        echo "  demo.ENG demo.QA demo.LLE demo.PROD"
        echo "In ./hostlist it will create empty files:"
        echo "  demo.ENG demo.QA demo.LLE demo.PROD"
        echo "In ./ it will touch file SCRIPT"
}

function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX="$(getPrefix)"
    echo ENG_PARAMFILE="$ENG_PARAMFILE"
    echo ENG_HOSTLIST="$ENG_HOSTLIST"
    echo QA_PARAMFILE="$QA_PARAMFILE"
    echo QA_HOSTLIST="$QA_HOSTLIST"
    echo LLE_PARAMFILE="$LLE_PARAMFILE"
    echo LLE_HOSTLIST="$LLE_HOSTLIST"
    echo PROD_PARAMFILE="$PROD_PARAMFILE"
    echo PROD_HOSTLIST="$PROD_HOSTLIST"
    echo "==== END PARAMETERS ===="
    if test -z "PREFIX" || test -z "ENG_PARAMFILE" || test -z "ENG_HOSTLIST" || test -z "QA_PARAMFILE" || \
       test -z "QA_HOSTLIST" || test -z "LLE_PARAMFILE" || test -z "LLE_HOSTLIST" || \
       test -z "PROD_PARAMFILE" || test -z "PROD_HOSTLIST"
    then
        error_out 1 "one of the parameters is empty"
    fi
}

if test "$SCRIPT" == "--help" || test "$SCRIPT" == "-h"
then
    usage
    exit 0
fi


## check for required parameters
if test -z "$SCRIPT"
then
    usage
    exit 1
fi

## getPrefix and assertScriptInCWD give a sanity check - that script and CWD are in an appropriate directory
assertScriptInCWD "$SCRIPT"
assertScriptSuffix "$SCRIPT"
PREFIX="$(getPrefix)"
error_out $? "$PREFIX"

ENG_PARAMFILE="$(_getParamFileName "$SCRIPT").ENG"
ENG_HOSTLIST="$(_getHostlistFileName "$SCRIPT").ENG"
QA_PARAMFILE="$(_getParamFileName "$SCRIPT").QA"
QA_HOSTLIST="$(_getHostlistFileName "$SCRIPT").QA"
LLE_PARAMFILE="$(_getParamFileName "$SCRIPT").LLE"
LLE_HOSTLIST="$(_getHostlistFileName "$SCRIPT").LLE"
PROD_PARAMFILE="$(_getParamFileName "$SCRIPT").PROD"
PROD_HOSTLIST="$(_getHostlistFileName "$SCRIPT").PROD"

showparams

echo ======= START: creating template directories =======
mkdir -pv params
mkdir -pv hostlist
mkdir -pv scripttype
mkdir -pv parallelize
echo ======= END: creating template directories =======
echo ======= START: creating param templates for each lane ======
for file in $ENG_PARAMFILE $QA_PARAMFILE $LLE_PARAMFILE $PROD_PARAMFILE
do
    if test -f "$file"
    then
        echo backing up old param file $file
        cp -vf $file $file.`date +%Y%m%d_%H%M%S`
    fi
    cp -v /unixworks/bl_tools/templates/params "$file"
done
echo ======= END: creating param templates ======
echo ======= START: creating empty hostfiles for each lane ======
for file in $ENG_HOSTLIST $QA_HOSTLIST $LLE_HOSTLIST $PROD_HOSTLIST
do
    if test -f "$file"
    then
        echo backing up old host file $file
        cp -vf $file $file.`date +%Y%m%d_%H%M%S`
    fi
    echo creating new hostfile $file
    > "$file"
echo ======= END: creating empty hostfiles for each lane ======
done
echo 
echo ================================
echo ======= START: set script type =======
echo please enter --once, --each, --perl, or --nexec
    cat <<HELP
    --once                execute once passing a hostlist as parameter - runs as bladmin
    --each                execute on each host (runscript) - runs as bladmin
    --perl                execute using perl interpreter
    --nexec               copy and nexec -- default -- for non-nsh scripts
HELP
TYPE=
while test -z "$TYPE"
do
    read -p "type (--once,--each,--perl,--nexec)> " TYPE
    if ! echo $TYPE | egrep -q "^\-\-(once|each|perl|nexec)$"
    then
        TYPE=
    fi
done
SCRIPTTYPE_FILE="$(getScriptTypeName "$SCRIPT")"
echo $TYPE > $SCRIPTTYPE_FILE
echo ======= END: set script type =======
echo ======= START: set parallelization type =======
echo "how many servers should the jobs run on at once (between 1 and 250 - effective max is 250)"
N=
while test -z "$N"
do
    read -p "N (between 1 AND 250)> " N
    if (! echo $N | egrep -q "^[0-9]+$") || test "$N" -lt 1 || test "$N" -gt 250
    then
        N=
    fi
done
PARALLELIZE_FILE="$(getParallelizeFileName "$SCRIPT")"
echo $N > $PARALLELIZE_FILE
#SCRIPTTYPE="$(getScriptType "$SCRIPT")"
#echo SCRIPTTYPE_FILE=$SCRIPTTYPE_FILE
#echo SCRIPTTYPE=$SCRIPTTYPE
#if ! test -f "$SCRIPTTYPE_FILE" || ! echo $SCRIPTTYPE | egrep -q "^\-\-|(once|each|perl|nexec)$"
#then
#    echo "WARNING: you probably want file \"$SCRIPTTYPE_FILE\" to contain one of --once, --each, --perl, --nexec"
#    cat <<HELP
#    --once                execute once passing a hostlist as parameter - runs as bladmin
#    --each                execute on each host (runscript) - runs as bladmin
#    --perl                execute using perl interpreter
#    --nexec               copy and nexec -- default -- for non-nsh scripts
#HELP
#fi
