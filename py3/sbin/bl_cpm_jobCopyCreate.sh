#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"
COPY="$2"
SELF="$(basename "$0")"

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
    echo PREFIX="$PREFIX"
    echo PARAMFILE="$PARAMFILE"
    echo HOSTLIST="$HOSTLIST"
    echo SRCJOB="$SRCJOB"
    echo DSTJOB="$DSTJOB"
    echo PROFILE="$PROFILE"
    echo ROLE="$ROLE"
    echo "==== END PARAMETERS ===="
    if test -z "$PREFIX" || test -z "$PARAMFILE" || test -z "$HOSTLIST" || test -z "$SRCJOB" || \
       test -z "$DSTJOB" || test -z "$PROFILE" || test -z "$ROLE"
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

if test "$SELF" = "bl_cpm_jobCopyCreate.sh"
then 
    error_out 1 "$0 is a template.  See the other jobs ending in jobCopyCreate{ENG,QA,LLE,PROD}."
elif test "$SELF" = "bl_cpm_jobCopyCreateENG.sh"
then
    PROFILE="$BL_ENG_PROFILE"
    ROLE="$BL_ENG_ROLE"
    PARAMFILE="$(getParamFileENG "$COPY")"
    HOSTLIST="$(getHostlistFileENG "$COPY")"
    SRCJOB="$(getJobLocationENG "$SCRIPT")"
    DSTJOB="$(getJobLocationENG "$COPY")"
elif test "$SELF" = "bl_cpm_jobCopyCreateQA.sh"
then
    ## ENG HERE BECAUSE QA CANNOT CREATE ITS OWN JOBS
    PROFILE="$BL_QA_PROFILE"
    ROLE="$BL_QA_ROLE"
    PARAMFILE="$(getParamFileQA "$COPY")"
    HOSTLIST="$(getHostlistFileQA "$COPY")"
    SRCJOB="$(getJobLocationQA "$SCRIPT")"
    DSTJOB="$(getJobLocationQA "$COPY")"
elif test "$SELF" = "bl_cpm_jobCopyCreateLLE.sh"
then
    PROFILE="$BL_LLE_PROFILE"
    ROLE="$BL_LLE_ROLE"
    PARAMFILE="$(getParamFileLLE "$COPY")"
    HOSTLIST="$(getHostlistFileLLE "$COPY")"
    SRCJOB="$(getJobLocationLLE "$SCRIPT")"
    DSTJOB="$(getJobLocationLLE "$COPY")"
elif test "$SELF" = "bl_cpm_jobCopyCreatePROD.sh"
then 
    PROFILE="$BL_PROD_PROFILE"
    ROLE="$BL_PROD_ROLE"
    PARAMFILE="$(getParamFilePROD "$COPY")"
    HOSTLIST="$(getHostlistFilePROD "$COPY")"
    SRCJOB="$(getJobLocationPROD "$SCRIPT")"
    DSTJOB="$(getJobLocationPROD "$COPY")"
else
    error_out 1 "$0 is not a valid filename for this script."
fi
## these give the sanity check
showparams
assertScriptInCWD "$COPY"

bl_conf_auto "BL_ENG_PROFILE" "$BL_ENG_PROFILE"
echo; echo; echo
echo ======= START: delete DSTJOB=\"$DSTJOB\" ======
echo bl_deljob --job="$DSTJOB"
bl_deljob --job="$DSTJOB"
warn_out $? "could not delete job \"$DSTJOB\""
echo ======= END: delete DSTJOB=\"$DSTJOB\" ======
echo; echo; echo
echo ======= START: copy $DSTJOB from $SRCJOB ======
echo bl_copyjob --srcjob="$SRCJOB" --dstjob="$DSTJOB"
bl_copyjob --srcjob="$SRCJOB" --dstjob="$DSTJOB"
error_out $? "could not copy \"$SRCJOB\" to \"$DSTJOB\""
echo ======= END: copy $DSTJOB from $SRCJOB ======
echo; echo; echo
for perm in Read Execute ModifyTargets Modify Cancel
do
    echo "===== START: granting NSHScriptJob.$perm on job \"$DSTJOB\" to role \"$ROLE\" ====="
    bl_addperm --jobobject "$DSTJOB" --role "$ROLE" --authname NSHScriptJob.$perm
    error_out $? "couldnt grant NSHScriptJob.Read on job \"$DSTJOB\" to role \"$ROLE\" ====="
    echo "===== END: granting NSHScriptJob.$perm on job \"$DSTJOB\" to role \"$ROLE\" ====="
    echo; echo; echo;
done
#echo "===== START: granting NSHScriptJob.Execute on job \"$DSTJOB\" to role \"$ROLE\" ====="
#bl_addperm --jobobject "$DSTJOB" --role "$ROLE" --authname NSHScriptJob.Execute
#error_out $? "couldn't grant NSHScriptJob.Execute on job \"$DSTJOB\" to role \"$ROLE\""
#echo "===== END: granting NSHScriptJob.Execute on job \"$DSTJOB\" to role \"$ROLE\" ====="
#echo; echo; echo;
#echo "===== START: granting NSHScriptJob.ModifyTargets on job \"$DSTJOB\" to role \"$ROLE\" ====="
#bl_addperm --jobobject "$DSTJOB" --role "$ROLE" --authname NSHScriptJob.ModifyTargets
#error_out $? "couldn't grant NSHScriptJob.ModifyTargets on job \"$DSTJOB\" to role \"$ROLE\""
#echo "===== END: granting NSHScriptJob.Execute on job \"$DSTJOB\" to role \"$ROLE\" ====="
#echo; echo; echo;
echo "===== START: adding params from \"$PARAMFILE\" to job \"$DSTJOB\" ====="
add_job_params "$PARAMFILE" "$DSTJOB"
error_out $? "there was a problem adding params from \"$PARAMFILE\" to job \"$COPY\""
echo "===== END: adding params from \"$PARAMFILE\" to job \"$DSTJOB\" ====="
