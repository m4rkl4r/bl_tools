#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
SELF="$(basename "$0")"

function usage() {
        echo USAGE: $0 PREFIX SCRIPT PARAMFILE ADDSCRIPT_PARAM
        echo
        echo "PREFIX will be appended to $BL_ENG_BASE (or used in its place if starting with a slash).  Use \"\" if prefix is empty."
        echo "Example: If developing in /unixworks/bl_tools/eng/APP/MLR/script.nsh, prefix APPS/MLR will give $BL_ENG_BASE/APPS/MLR."
        echo "The file referenced by SCRIPT will be placed in depot group PREFIX"
        echo "PARAMFILE contains parameters that should be added to the script, in order, one per line"
        echo "  -- each line should contain two required values + optional DESCRIPTION - use quotes there are spaces"
        echo "      \"PARAMNAME\"   \"PARAMVAL\"    \"DECRIPTION\""
        echo "ADDSCRIPT_PARAM (optional) should be one of --once, --each, --perl, --nexec (default)"
}

function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX=$PREFIX
    echo SCRIPT=$SCRIPT
    echo JOB=$JOB
    echo GROUP=$GROUP
    echo PROFILE=$PROFILE
    echo PROFILENAME=$PROFILENAME
    echo ROLE=$ROLE
    echo HOSTLIST=$HOSTLIST
    echo "==== END PARAMETERS ===="
    if test -z "$PREFIX" || test -z "$SCRIPT" || test -z "$JOB" || test -z "$GROUP" || \
       test -z "$PROFILE" || test -z "$PROFILENAME" || test -z "$ROLE" || test -z "$HOSTLIST"
    then
        echo
        error_out 1 "there are blank mandatory parameters in showparams"
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

if test "$SELF" = "bl_cpm_setJobHosts.sh"
then
    error_out 1 "$0 is a template. See the other jobs ending in set\$\{something\}JobHosts.sh"
elif test "$SELF" = bl_cpm_setJobHostsLLE.sh  
then
    PROFILENAME="BL_LLE_PROFILE"
    PROFILE="$BL_LLE_PROFILE"
    ROLE="$BL_LLE_ROLE"
    JOB="$(getJobLocationLLE "$SCRIPT")"
    GROUP="$(dirname "$JOB")"
    HOSTLIST="$(getHostlistFileLLE "$SCRIPT")"
elif test "$SELF" = bl_cpm_setJobHostsPROD.sh  
then
    PROFILENAME="BL_PROD_PROFILE"
    PROFILE="$BL_PROD_PROFILE"
    ROLE="$BL_PROD_ROLE"
    JOB="$(getJobLocationPROD "$SCRIPT")"
    GROUP="$(dirname "$JOB")"
    HOSTLIST="$(getHostlistFilePROD "$SCRIPT")"
elif test "$SELF" = bl_cpm_setJobHostsQA.sh  
then
    PROFILENAME="BL_QA_PROFILE"
    PROFILE="$BL_QA_PROFILE"
    ROLE="$BL_QA_ROLE"
    JOB="$(getJobLocationQA "$SCRIPT")"
    GROUP="$(dirname "$JOB")"
    HOSTLIST="$(getHostlistFileQA "$SCRIPT")"
fi

showparams

bl_conf_auto "BL_ENG_PROFILE" "$BL_ENG_PROFILE"
echo "==== temporarily adding NSHScriptJob.ModifyTargets to \"$JOB\" for role \"$ROLE\" ===="
bl_addperm --jobobject "$JOB" --role "$ROLE" --authname NSHScriptJob.ModifyTargets
error_out $? "couldnot add NSHScriptJob.ModifyTargets to \"$JOB\" for role \"$ROLE\""
echo; echo; echo

bl_conf_auto "$PROFILENAME" "$PROFILE"
echo "==== removing target hosts from job \"$JOB\" ===="
bl_job_delservers --job "$JOB" --all
error_out $? "could not delete hosts from job \"$JOB\""
echo; echo; echo
echo "==== adding hosts to job \"$JOB\" from \"$HOSTLIST\" ===="
test -n "$HOSTLIST" && ls -ld "$HOSTLIST" && bl_job_addservers --job "$JOB" --serverfile "$HOSTLIST"
warn_out $? "could not add hosts to job \"$JOB\" from file \"$HOSTLIST\""
echo; echo; echo

bl_conf_auto "BL_ENG_PROFILE" "$BL_ENG_PROFILE"
echo "==== removing NSHScriptJob.ModifyTargets from \"$JOB\" for role \"$ROLE\" ===="
bl_delperm --jobobject "$JOB" --role "$ROLE" --authname NSHScriptJob.ModifyTargets
error_out $? "could not remove NSHScriptJob.ModifyTargets from \"$JOB\" for role \"$ROLE\""
echo; echo; echo
