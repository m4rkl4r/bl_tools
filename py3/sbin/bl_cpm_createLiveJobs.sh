#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
ENG_PROFILE=eng

function usage() {
        echo USAGE: $0 SCRIPT
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT"
        echo "This will create the lle and prod deployeradv jobs in:"
        echo "  BL_LLE_BASE/PREFIX=$BL_LLE_BASE/PREFIX"
        echo "  BL_PROD_BASE/PREFIX=$BL_PROD_BASE/PREFIX"
        echo ""
        echo "PREFIX refers to the part of CWD that comes after BL_LOCAL_ENG but _before_ SCRIPT"
}

function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX=$PREFIX
    echo DEPOTSCRIPT=$DEPOTSCRIPT
    echo BL_LLE_BASE=$BL_LLE_BASE
    echo BL_PROD_BASE=$BL_PROD_BASE
    echo LLE_JOB=$LLE_JOB
    echo LLE_GROUP=$LLE_GROUP
    echo LLE_PARAMFILE=$LLE_PARAMFILE
    echo PROD_JOB=$PROD_JOB
    echo PROD_GROUP=$PROD_GROUP
    echo PROD_PARAMFILE=$PROD_PARAMFILE
    echo BL_LLE_ROLE=$BL_LLE_ROLE
    echo BL_PROD_ROLE=$BL_PROD_ROLE
    echo "==== END PARAMETERS ===="
    if test -z "$PREFIX" || test -z "$DEPOTSCRIPT" || test -z "$BL_LLE_BASE" || test -z "$BL_PROD_BASE" || \
       test -z "$LLE_JOB" || test -z "$LLE_GROUP" || test -z "$LLE_PARAMFILE" || test -z "$PROD_JOB" || \
       test -z "$PROD_GROUP" || test -z "$PROD_PARAMFILE" || test -z "$BL_LLE_ROLE" || test -z "$BL_PROD_ROLE"
    then
        error_out 1 "a variable was left undefined in showparams"
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

assertScriptInCWD "$SCRIPT"
assertScriptSuffix "$SCRIPT"
PREFIX="$(getPrefix)"
error_out $? "$PREFIX"

assertParallelize "$SCRIPT"
PARALLELIZE="$(getParallelize "$SCRIPT")"
if test -n "$PARALLELIZE"
then
    PARALLELIZE="--parallelize=$PARALLELIZE"
fi

DEPOTSCRIPT="$(getDepotScriptLocationREL "$SCRIPT")"
LLE_JOB="$(getJobLocationLLE "$SCRIPT")"
LLE_GROUP="$(dirname "$LLE_JOB")"
LLE_PARAMFILE="$(getParamFileLLE "$SCRIPT")"
LLE_HOSTLIST="$(getHostlistFileLLE "$SCRIPT")"

PROD_JOB="$(getJobLocationPROD "$SCRIPT")"
PROD_GROUP="$(dirname "$PROD_JOB")"
PROD_PARAMFILE="$(getParamFilePROD "$SCRIPT")"
PROD_HOSTLIST="$(getHostlistFilePROD "$SCRIPT")"

showparams

bl_conf_auto BL_ENG_PROFILE "$BL_ENG_PROFILE"

echo "==== creating LLE job \"$LLE_JOB\" ===="
echo "===== making sure \"$LLE_GROUP\" exists ====="
bl_mkdir --jobgroup "$LLE_GROUP"
error_out $? "could not mkdir job group \"$LLE_GROUP\""
echo; echo; echo;
echo "===== recursively applying acl \"$BL_LLE_BASE\" to folders in path \"$PREFIX\" in \"$BL_LLE_BASE\" ====="
traverse_apply_acl_template "$BL_LLE_BASE" "$PREFIX" "$BL_LLE_TEMPLATE" job
error_out $? "could not apply template \"$BL_LLE_TEMPLATE\" to folders in path \"$PREFIX\" in \"$BL_LLE_BASE\""
echo; echo; echo;
echo "===== deleting old job \"$LLE_JOB\" ====="
bl_deljob --job "$LLE_JOB"
warn_out $? "could not delete old job \"$LLE_JOB\""
echo; echo; echo;
echo "===== adding job \"$LLE_JOB\" ====="
bl_addjob --depotscript "$DEPOTSCRIPT" --job "$LLE_JOB" $PARALLELIZE
error_out $? "could not add job \"$LLE_JOB\" from script \"$DEPOTSCRIPT\""
echo; echo; echo;
for perm in Read Execute ModifyTargets Modify Cancel
do
    echo "===== granting NSHScriptJob.$perm on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
    bl_addperm --jobobject "$LLE_JOB" --role "$BL_LLE_ROLE" --authname NSHScriptJob.$perm
    error_out $? "couldnt grant NSHScriptJob.$perm on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
    echo; echo; echo;
done
#echo "===== granting NSHScriptJob.Execute on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#bl_addperm --jobobject "$LLE_JOB" --role "$BL_LLE_ROLE" --authname NSHScriptJob.Execute
#error_out $? "couldnt grant NSHScriptJob.Execute on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#echo; echo; echo;
#echo "===== granting NSHScriptJob.ModifyTargets on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#bl_addperm --jobobject "$LLE_JOB" --role "$BL_LLE_ROLE" --authname NSHScriptJob.ModifyTargets
#error_out $? "couldnt grant NSHScriptJob.ModifyTargets on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#echo; echo; echo;
#echo "===== granting NSHScriptJob.Modify on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#bl_addperm --jobobject "$LLE_JOB" --role "$BL_LLE_ROLE" --authname NSHScriptJob.Modify
#error_out $? "couldnt grant NSHScriptJob.Modify on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#echo; echo; echo;
#echo "===== granting NSHScriptJob.Cancel on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#bl_addperm --jobobject "$LLE_JOB" --role "$BL_LLE_ROLE" --authname NSHScriptJob.Cancel
#error_out $? "couldnt grant NSHScriptJob.Cancel on job \"$LLE_JOB\" to role \"$BL_LLE_ROLE\" ====="
#echo; echo; echo;
echo "==== adding params to job \"$LLE_JOB\" from \"$LLE_PARAMFILE\" ===="
add_job_params "$LLE_PARAMFILE" "$LLE_JOB"
error_out $? "could not add params to job \"$LLE_JOB\" from file \"$LLE_PARAMFILE\""
echo; echo; echo;

echo "==== creating PROD job \"$PROD_JOB\" ===="
echo "===== making sure \"$PROD_GROUP\" exists ====="
bl_mkdir --jobgroup "$PROD_GROUP"
error_out $? "could not mkdir job group \"$PROD_GROUP\""
echo; echo; echo;
echo "===== recursively applying acl \"$BL_PROD_BASE\" to folders in path \"$PREFIX\" in \"$BL_PROD_BASE\" ====="
traverse_apply_acl_template "$BL_PROD_BASE" "$PREFIX" "$BL_PROD_TEMPLATE" job
error_out $? "could not apply template \"$BL_PROD_TEMPLATE\" to folders in path \"$PREFIX\" in \"$BL_PROD_BASE\""
echo; echo; echo;
echo "===== deleting old job \"$PROD_JOB\" ====="
bl_deljob --job "$PROD_JOB"
warn_out $? "could not delete old job \"$PROD_JOB\""
echo; echo; echo;
echo "===== adding job \"$PROD_JOB\" ====="
bl_addjob --depotscript "$DEPOTSCRIPT" --job "$PROD_JOB" $PARALLELIZE
error_out $? "could not add job \"$PROD_JOB\" from script \"$DEPOTSCRIPT\""
echo; echo; echo;
for perm in Read Execute ModifyTargets Modify Cancel
do
    echo "===== granting NSHScriptJob.$perm on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
    bl_addperm --jobobject "$PROD_JOB" --role "$BL_PROD_ROLE" --authname NSHScriptJob.$perm
    error_out $? "couldnt grant NSHScriptJob.$perm on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
    echo; echo; echo;
done
#echo "===== granting NSHScriptJob.Execute on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
#bl_addperm --jobobject "$PROD_JOB" --role "$BL_PROD_ROLE" --authname NSHScriptJob.Execute
#error_out $? "couldnt grant NSHScriptJob.Execute on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
#echo; echo; echo;
#echo "===== granting NSHScriptJob.ModifyTargets on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
#bl_addperm --jobobject "$PROD_JOB" --role "$BL_PROD_ROLE" --authname NSHScriptJob.ModifyTargets
#error_out $? "couldnt grant NSHScriptJob.ModifyTargets on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
#echo; echo; echo;
#echo; echo; echo;
#echo "===== granting NSHScriptJob.Modify on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
#bl_addperm --jobobject "$PROD_JOB" --role "$BL_PROD_ROLE" --authname NSHScriptJob.Modify
#error_out $? "couldnt grant NSHScriptJob.Modify on job \"$PROD_JOB\" to role \"$BL_PROD_ROLE\" ====="
echo "==== adding params to job \"$PROD_JOB\" from \"$PROD_PARAMFILE\" ===="
add_job_params "$PROD_PARAMFILE" "$PROD_JOB"
error_out $? "could not add params to job \"$PROD_JOB\" from file \"$PROD_PARAMFILE\""
echo; echo; echo;
