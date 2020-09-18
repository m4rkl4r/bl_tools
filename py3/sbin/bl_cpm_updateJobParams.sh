#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
COPY="$2"
SELF="$(basename "$0")"

function usage() {
        echo USAGE: $0 SCRIPT
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT"
        echo ""
        echo "This will clear the parameters assigned to the JOB (named after SCRIPT),"
        echo "and then add parameters from the templates in ./params."
        echo ""
        echo "EXAMPLE: bl_cpm_updateJobParamsENG.xh demo.0.nsh"
        echo "This will add parameters defined in params/demo.ENG"
}

function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX="$PREFIX"
    echo PROFILE="$PROFILE"
    echo ROLE="$ROLE"
    echo PARAMFILE="$PARAMFILE"
    echo JOB="$JOB"
    echo "==== END PARAMETERS ===="
    if test -z "$PREFIX" || test -z "$PARAMFILE" || test -z "$JOB" || \
       test -z "$PROFILE" || test -z "$ROLE"
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

assertScriptInCWD "$SCRIPT"
assertScriptSuffix "$SCRIPT"
PREFIX="$(getPrefix)"
error_out $? "$PREFIX"

if test "$SELF" = "bl_cpm_updateJobParams.sh"
then 
    error_out 1 "$0 is a template.  See the other scripts named bl_cpm_updateJobParams{ENG,QA,LLE,PROD}."
elif test "$SELF" = "bl_cpm_updateJobParamsENG.sh"
then
    PROFILE="$BL_ENG_PROFILE"
    ROLE="$BL_ENG_ROLE"
    PARAMFILE="$(getParamFileENG "$SCRIPT")"
    JOB="$(getJobLocationENG "$SCRIPT")"
elif test "$SELF" = "bl_cpm_updateJobParamsQA.sh"
then
    ## ENG HERE BECAUSE QA CANNOT CREATE ITS OWN JOBS
    PROFILE="$BL_QA_PROFILE"
    ROLE="$BL_QA_ROLE"
    PARAMFILE="$(getParamFileQA "$SCRIPT")"
    JOB="$(getJobLocationQA "$SCRIPT")"
elif test "$SELF" = "bl_cpm_updateJobParamsLLE.sh"
then
    PROFILE="$BL_LLE_PROFILE"
    ROLE="$BL_LLE_ROLE"
    PARAMFILE="$(getParamFileLLE "$SCRIPT")"
    JOB="$(getJobLocationLLE "$SCRIPT")"
elif test "$SELF" = "bl_cpm_updateJobParamsPROD.sh"
then 
    PROFILE="$BL_PROD_PROFILE"
    ROLE="$BL_PROD_ROLE"
    PARAMFILE="$(getParamFilePROD "$SCRIPT")"
    JOB="$(getJobLocationPROD "$SCRIPT")"
else
    error_out 1 "$0 is not a valid filename for this script."
fi
## these give the sanity check
showparams
assertScriptInCWD "$SCRIPT"

if test -n "$BL_ENG_PROFILE"
then
        bl_conf_auto "BL_ENG_PROFILE" "$BL_ENG_PROFILE"
elif test -n "$BL_QA_PROFILE"
then
        bl_conf_auto "BL_QA_PROFILE" "$BL_QA_PROFILE"
else
    echo $SELF requires environment variable BL_ENG_PROFILE or BL_QA_PROFILE
    echo EXITING 1
    exit 1
fi
echo "===== START: clearing params from job \"$JOB\" ====="
bl_param_clearvalues_nshscriptjob --job "$JOB"
error_out $? "there was a problem clearing params from job \"$JOB\""
echo; echo; echo
echo "===== END: clearing params from job \"$JOB\" ====="
echo "===== START: adding params from \"$PARAMFILE\" to job \"$JOB\" ====="
add_job_params "$PARAMFILE" "$JOB"
error_out $? "there was a problem adding params from \"$PARAMFILE\" to job \"$JOB\""
echo "===== END: adding params from \"$PARAMFILE\" to job \"$JOB\" ====="
