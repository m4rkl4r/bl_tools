#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
COPY="$2"

function usage() {
        echo USAGE: $0 SCRIPT COPYNAME
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT COPYNAME"
        echo ""
        echo "This will create symbolic link from SCRIPT to COPYNAME,"
        echo "and create parameter templates in ./params if they don't exist."
        echo "COPYNAME should include version number and shell suffix."
        echo ""
        echo "EXAMPLE: $0 demo.0.nsh democopy.0.nsh"
        echo "This will create a link from demo.0.nsh to democopy.0.nsh"
        echo "In ./params, it will create templates called:"
        echo "  democopy.ENG democopy.QA democopy.LLE democopy.PROD"
        echo "In ./hostlist it will create empty files:"
        echo "  democopy.ENG democopy.QA democopy.LLE democopy.PROD"
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
ENG_PARAMFILE="$(_getParamFileName "$COPY").ENG"
ENG_HOSTLIST="$(_getHostlistFileName "$COPY").ENG"
QA_PARAMFILE="$(_getParamFileName "$COPY").QA"
QA_HOSTLIST="$(_getHostlistFileName "$COPY").QA"
LLE_PARAMFILE="$(_getParamFileName "$COPY").LLE"
LLE_HOSTLIST="$(_getHostlistFileName "$COPY").LLE"
PROD_PARAMFILE="$(_getParamFileName "$COPY").PROD"
PROD_HOSTLIST="$(_getHostlistFileName "$COPY").PROD"

showparams

echo; echo; echo
echo ======= START: creating link original script to new script name =======
SCRIPT_TYPE=$(echo $SCRIPT | awk -F. '{ print $NF }')
SCRIPT_VER=$(echo $SCRIPT | awk -F. '{ print $(NF-1) }')
COPY_TYPE=$(echo $COPY | awk -F. '{ print $NF }')
COPY_VER=$(echo $COPY | awk -F. '{ print $(NF-1) }')

echo SCRIPT_TYPE=$SCRIPT_TYPE
echo SCRIPT_VER=$SCRIPT_VER
echo COPY_TYPE=$COPY_TYPE
echo COPY_VER=$COPY_VER
if ! echo $SCRIPT_TYPE | egrep -q "^(nsh|sh)$" || ! echo $SCRIPT_VER | egrep -q "^[0-9]+$" || \
   ! echo $COPY_TYPE | egrep -q "^(nsh|sh)$" || ! echo $COPY_VER | egrep -q "^[0-9]+$"
then
    error_out 1 "SCRIPT and COPY must end in .NN.sh or .NN.nsh, where NN is an integer 0 or larger"
elif test "$SCRIPT_TYPE" != "$COPY_TYPE" || test "$SCRIPT_VER" != "$COPY_VER"
then
    error_out 1 "SCRIPT and COPY must have the same version number and script suffix"
elif ! echo $COPY | egrep -q "^[a-zA-Z0-9]"
then
    error_out 1 "COPY must be in CWD"
fi
ln -vs "$SCRIPT" "$COPY" || error_out $? "looks like COPY=\"$COPY\" already exists"
echo ======= END: creating link original script to new script name =======
echo; echo; echo;
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
done
echo ======= END: creating empty hostfiles for each lane ======
