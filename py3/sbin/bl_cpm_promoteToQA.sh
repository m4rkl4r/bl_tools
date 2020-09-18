#!/bin/bash
# created by mark price, June 2019
# 2019-08-13 - added bits to create dotfiles when promoting a job
. /unixworks/bl_tools/etc/promotion.sh
SCRIPT="$1"

PROMOTESTART=".promoteToQA.started.$SCRIPT"
PROMOTEFINISH=".promoteToQA.finished.$SCRIPT"

function usage() {
        echo USAGE: $0 SCRIPT
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT"
        echo ""
        echo "This will copy the depot script:"
        echo "  from BL_ENG_BASE/PREFIX/dev"
        echo "  to   BL_ENG_BASE/PREFIX/rel"
        echo ""
        echo "PREFIX refers to the part of CWD that comes after BL_LOCAL_ENG but _before_ SCRIPT"
}

function showparams() {
    echo
    echo "==== START PARAMETERS ===="
    echo PREFIX=$PREFIX
    echo PREFIX_REL=$PREFIX_REL
    echo PREFIX_DEV=$PREFIX_DEV
    echo SCRIPT=$SCRIPT
    echo DEPOTSCRIPT_DEV=$DEPOTSCRIPT_DEV
    echo DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL
    echo DEPOTGROUP_DEV=$DEPOTGROUP_DEV
    echo DEPOTGROUP_REL=$DEPOTGROUP_REL
    echo QA_JOBGROUP=$QA_JOBGROUP
    echo QA_JOB=$QA_JOB
    echo PARAMFILE_QA=$PARAMFILE_QA
    echo HOSTLIST_QA=$HOSTLIST_QA
    echo "==== STOP PARAMETERS ===="
    echo
    if test -z "$PREFIX" || test -z "$PREFIX_REL" || test -z "$PREFIX_DEV" || test -z "$SCRIPT" || \
       test -z "$DEPOTSCRIPT_DEV" || test -z "$DEPOTSCRIPT_REL" || test -z "$DEPOTGROUP_DEV" || \
       test -z "$DEPOTGROUP_REL" || test -z "$QA_JOBGROUP" || test -z "$QA_JOB" || \
       test -z "$PARAMFILE_QA" || test -z "$HOSTLIST_QA"
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

assertParallelize "$SCRIPT"
PARALLELIZE="$(getParallelize "$SCRIPT")"
if test -n "$PARALLELIZE"
then
    PARALLELIZE="--parallelize=$PARALLELIZE"
fi

PREFIX_REL="$PREFIX/rel"
PREFIX_DEV="$PREFIX/dev"
DEPOTSCRIPT_DEV="$(getDepotScriptLocationDEV "$SCRIPT")"
DEPOTSCRIPT_REL="$(getDepotScriptLocationREL "$SCRIPT")"
DEPOTGROUP_DEV="$(dirname "$DEPOTSCRIPT_DEV")"
DEPOTGROUP_REL="$(dirname "$DEPOTSCRIPT_REL")"
QA_JOB="$(getJobLocationQA "$SCRIPT")"
QA_JOBGROUP="$(dirname "$QA_JOB")"
PARAMFILE_QA="$(getParamFileQA "$SCRIPT")"
HOSTLIST_QA="$(getHostlistFileQA "$SCRIPT")"

if test -z "$DEPOTSCRIPT_DEV" || test -z "$DEPOTSCRIPT_REL"
then
    echo DEPOTSCRIPT_DEV=\"$DEPOTSCRIPT_DEV\"
    echo DEPOTSCRIPT_REL=\"$DEPOTSCRIPT_REL\"
    echo
    echo please look into this
    echo EXITING 1
    exit 1
fi

showparams

bl_conf_auto BL_ENG_PROFILE "$BL_ENG_PROFILE"

echo; echo; echo

if test -f "$PROMOTESTART" || test -f "$PROMOTEFINISH"
then
    echo "please demote \"$SCRIPT\" before running $0"
    exit 1
fi

if ! touch "$PROMOTESTART"
then
    echo "$0: could not touch "$PROMOTESTART" - exiting."
    exit 2
fi

echo "==== deleting DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL ===="
bl_delscript --depotscript "$DEPOTSCRIPT_REL"
warn_out $ERR "could not delete depot script \"$DEPOTSCRIPT_REL\""
echo; echo; echo

echo "==== mkdir DEPOTSCRIPT_REL=$DEPOTGROUP_REL ===="
bl_mkdir --depotgroup "$DEPOTGROUP_REL"
error_out $? "could not mkdir depot group \"$DEPOTGROUP_REL\"."
echo; echo; echo

echo "==== recursively give role \"$BL_QA_ROLE\"  \"DepotFolder.Read\" perms on groups/folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" ===="
echo traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_QA_ROLE" depot
traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_QA_ROLE" depot
error_out $? "error adding DepotFolder.Read to folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" for role \"$BL_QA_ROLE\""
echo; echo; echo

echo "==== recursively give role \"$BL_LLE_ROLE\"  \"DepotFolder.Read\" perms on groups/folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" ===="
echo traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_LLE_ROLE" depot
traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_LLE_ROLE" depot
error_out $? "error adding DepotFolder.Read to folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" for role \"$BL_LLE_ROLE\""
echo; echo; echo

echo "==== recursively give role \"$BL_PROD_ROLE\" \"DepotFolder.Read\" perms on groups/folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" ===="
echo traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_PROD_ROLE" depot
traverse_apply_perm "$BL_ENG_BASE" "$PREFIX_REL" DepotFolder.Read "$BL_PROD_ROLE" depot
error_out $? "error adding DepotFolder.Read to folders in \"$PREFIX_REL\" in \"$BL_ENG_BASE\" for role \"$BL_LLE_ROLE\""
echo; echo; echo

#echo "==== recursively add \"DepotGroup.Read\" perms to groups/folders in \"$(getPrefix)/rel\" in \"$BL_ENG_BASE\" for role \"$BL_QA_TEMPLATE\" ===="
#echo traverse_apply_perm "$BL_ENG_BASE" "$(getPrefix)/rel" DepotGroup.Read "$BL_QA_TEMPLATE" depot
#traverse_apply_perm "$BL_ENG_BASE" "$(getPrefix)/rel" DepotGroup.Read "$BL_QA_TEMPLATE" depot
#error_out $? "error adding DepotGroup to folders in \"${getPrefix}/rel\" in \"$BL_ENG_BASE\" for role \"$BL_QA_TEMPLATE\""
#echo

echo "==== copy DEPOTSCRIPT_DEV=$DEPOTSCRIPT_DEV TO DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL ===="
bl_copyDepotObject --srcobj "$DEPOTSCRIPT_DEV" --dstobj "$DEPOTSCRIPT_REL"
error_out $? "could not copy script DEPOTSCRIPT_DEV=\"$DEPOTSCRIPT_DEV\" to DEPOTSCRIPT_REL=\"$DEPOTSCRIPT_REL\""
echo; echo; echo

echo "==== updating ACL to add template \"$BL_QA_TEMPLATE\" to script \"$DEPOTSCRIPT_REL\" ===="
echo bl_applyAclTemplate --depotobject "$DEPOTSCRIPT_REL" --acl "$BL_QA_TEMPLATE"
bl_applyAclTemplate --depotobject "$DEPOTSCRIPT_REL" --acl "$BL_QA_TEMPLATE"
error_out $? "could not apply ACL template \"$BL_QA_TEMPLATE\" to DEPOTSCRIPT_REL=\"$DEPOTSCRIPT_REL\""
echo; echo; echo

echo "==== updating ACL to add NSHScript.Read to script \"$DEPOTSCRIPT_REL\" ===="
echo bl_addperm --depotobject "$DEPOTSCRIPT_REL" --authname "NSHScript.Read" --role "$BL_QA_ROLE"
bl_addperm --depotobject "$DEPOTSCRIPT_REL" --authname "NSHScript.Read" --role "$BL_QA_ROLE"
error_out $? "could not add NSHScript.Read to DEPOTSCRIPT_REL=\"$DEPOTSCRIPT_REL\""
echo; echo; echo

echo "==== creating job group \"$QA_JOBGROUP\" ===="
bl_mkdir --jobgroup "$QA_JOBGROUP"
error_out $? "job group creation failed for \"$QA_JOBGROUP\""
echo; echo; echo

echo "==== recursively add \"JobFolder.Read\" perms to job groups/folders in \"$PREFIX\" in \"$BL_QA_BASE\" for role \"$BL_QA_ROLE\" ===="
#echo traverse_apply_perm "$BL_QA_BASE" "$PREFIX" JobFolder.Read "$BL_QA_ROLE" job
traverse_apply_perm "$BL_QA_BASE" "$PREFIX" JobFolder.Read "$BL_QA_ROLE" job
error_out $? "error adding JobFolder.Read to folders in \"$PREFIX\" in \"$BL_ENG_BASE\" for role \"$BL_QA_ROLE\""
echo; echo; echo

#echo "==== updating ACL to add QA perms to job group \"$QA_JOBGROUP\" ===="
#bl_applyAclTemplate --jobobject "$QA_JOBGROUP" --acl "$BL_QA_TEMPLATE"
#error_out $? "could not apply acl template \"$BL_QA_TEMPLATE\" to \"$QA_JOBGROUP\""
#echo

echo "==== deleting old job \"$QA_JOB\" ===="
echo bl_deljob --job "$QA_JOB"
bl_deljob --job "$QA_JOB"
warn_out $? "WARNING could not delete old job \"$QA_JOB\""
echo; echo; echo

echo "==== creating job \"`basename $SCRIPT`\" in \"$QA_JOBGROUP\" ===="
bl_addjob  --depotscript "$DEPOTSCRIPT_REL" --job "$QA_JOB" $PARALLELIZE
error_out $? "could not create job \"$QA_JOB\""
echo; echo; echo

echo "==== updating ACL to add QA perms to job \"$QA_JOB\" ===="
echo bl_applyAclTemplate --jobobject "$QA_JOB" --acl "$BL_QA_TEMPLATE"
bl_applyAclTemplate --jobobject "$QA_JOB" --acl "$BL_QA_TEMPLATE"
error_out $? "could not apply acl template \"$BL_QA_TEMPLATE\" to \"$QA_JOB\""
echo; echo; echo

echo "==== adding parameters to job \"$QA_JOB\" ===="
add_job_params "$PARAMFILE_QA" "$QA_JOB"
error_out $? "could not add params in \"$PARAMFILE_QA\" to job \"$QA_JOBS\"."
echo; echo; echo

touch "$PROMOTEFINISH"
ERR=$?
if test $ERR != 0; then
    error_out $ERR "ERROR: could not touch \"$PROMOTEFINISH\""
fi

#echo "==== copying local file \"$SCRIPT\" to \"${SCRIPT}.release\" ===="
#cp -f "$SCRIPT" "${SCRIPT}.release"
#error_out $? "could not cp -f \"$SCRIPT\" \"${SCRIPT}.release\""
#echo; echo; echo
