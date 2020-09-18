#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh
SCRIPT="$1"

function usage() {
        echo USAGE: $0 SCRIPT$
        echo$
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"$
        echo "USAGE: $0 SCRIPT"$
        echo ""
        echo "This will unceremoniously rip out the jobs and scripts from jobgroups and depots in ENG, QA, DEPLOYERADV PROD and DEPLOYERADV NP"
	echo "Some removes will fail if the job isnt demoted"
}

function showparams() {
    echo
    echo "==== START PARAMETERS ===="
    echo SCRIPT=$SCRIPT
    echo DEPOTSCRIPT_DEV=$DEPOTSCRIPT_DEV
    echo DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL
    echo PROD_JOB=$PROD_JOB
    echo LLE_JOB=$LLE_JOB
    echo QA_JOB=$ENG_JOB
    echo ENG_JOB=$ENG_JOB
    echo "==== STOP PARAMETERS ===="
    echo
    if test -z "$SCRIPT" || test -z "$DEPOTSCRIPT_DEV" || test -z "$DEPOTSCRIPT_REL" || \
       test -z "$PROD_JOB" || test -z "$LLE_JOB" || test -z "$QA_JOB" || test -z "$ENG_JOB"
    then
        error_out 1 "a variable was left undefined in showparams"
    fi
}
if test "$SCRIPT" == "--help" || test "$PREFEX" == "-h"
then
    usage
    exit 0
elif test -z "$SCRIPT"
then
    usage
    exit 1
fi

assertScriptInCWD "$SCRIPT"
assertScriptSuffix "$SCRIPT"
PREFIX="$(getPrefix)"
error_out $? "$PREFIX"

export DEPOTSCRIPT_DEV="$(getDepotScriptLocationDEV "$SCRIPT")"
export DEPOTSCRIPT_REL="$(getDepotScriptLocationREL "$SCRIPT")"
export ENG_JOB="$(getJobLocationENG "$SCRIPT")"
export QA_JOB="$(getJobLocationQA "$SCRIPT")"
export LLE_JOB="$(getJobLocationLLE "$SCRIPT")"
export PROD_JOB="$(getJobLocationPROD "$SCRIPT")"

showparams

bl_conf_auto BL_ENG_PROFILE "$BL_ENG_PROFILE"

echo "===== START deleting PROD job $PROD_JOB ====="
bl_deljob --job "$PROD_JOB"
PRODERR=$?
echo "===== DONE deleting PROD job $PROD_JOB ====="
echo "===== START deleting LLE job $LLE_JOB ====="
bl_deljob --job "$LLE_JOB"
LLEERR=$?
echo "===== DONE deleting PROD job $PROD_JOB ====="
echo "===== START deleting QA job $QA_JOB ====="
bl_deljob --job "$QA_JOB"
QAERR=$?
echo "===== DONE deleting QA job $QA_JOB ====="
echo "===== START deleting ENG job $ENG_JOB ====="
bl_deljob --job "$ENG_JOB"
ENGERR=$?
echo "===== DONE deleting ENG job $ENG_JOB ====="
echo "===== START deleting release script $DEPOTSCRIPT_REL ====="
bl_delscript --depotscript "$DEPOTSCRIPT_REL"
RELSCRIPTERR=$?
echo "===== END deleting release script $DEPOTSCRIPT_REL ====="
echo "===== START deleting release script $DEPOTSCRIPT_DEV ====="
bl_delscript --depotscript "$DEPOTSCRIPT_DEV"
ENGSCRIPTERR=$?
echo "===== END deleting release script $DEPOTSCRIPT_DEV ====="

echo
echo
echo "===== failed deletes ====="
if ! test "$PRODERR" = 0; then echo error code $PRODERR deleting PROD job $PROD_JOB; fi
if ! test "$LLEERR" = 0; then echo error code $LLEERR deleting PROD job $LLE_JOB; fi
if ! test "$QAERR" = 0; then echo error code $QAERR deleting PROD job $QA_JOB; fi
if ! test "$ENGERR" = 0; then echo error code $ENGERR deleting PROD job $ENG_JOB; fi
if ! test "$RELSCRIPTERR" = 0; then echo error code $RELSCRIPTERR deleting release script $DEPOTSCRIPT_REL; fi
if ! test "$ENGSCRIPTERR" = 0; then echo error code $ENGSCRIPTERR deleting eng script $DEPOTSCRIPT_DEV; fi
