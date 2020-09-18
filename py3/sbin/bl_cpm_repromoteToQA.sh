#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"

PROMOTESTART=".promoteToQA.started.$SCRIPT"
PROMOTEFINISH=".promoteToQA.finished.$SCRIPT"
#PRE_DEMOTE_PERMS=".perms.before.demote.$SCRIPT"
#POST_REPROMOTE_PERMS=".perms.before.repromote.$SCRIPT"


function usage() {
        echo USAGE: $0 SCRIPT
        echo
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"
        echo "USAGE: $0 SCRIPT"$
        echo ""
        echo "This will make the depotscript in BL_ENG_BASE/PREFIX"
        echo "readable by only ENG, effectively disabling all job definitions."
        echo ""
        echo "PREFIX refers to the part of CWD that comes after BL_LOCAL_ENG but _before_ SCRIPT"
}
function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX=$PREFIX
    echo DEPOTSCRIPT=$SCRIPT
    echo BL_LLE_BASE=$BL_LLE_BASE
    echo BL_PROD_BASE=$BL_PROD_BASE
    echo LLE_JOB=$LLE_JOB
    echo LLE_GROUP=$LLE_JOB
    echo PROD_JOB=$PROD_JOB
    echo PROD_GROUP=$PROD_JOB
    echo "==== END PARAMETERS ===="
    if test -z "$PREFIX" || test -z "$SCRIPT" || test -z "$BL_LLE_BASE" || test -z "$BL_PROD_BASE" || \
       test -z "$LLE_JOB" || test -z "$LLE_JOB" || test -z "$PROD_JOB" || test -z "$PROD_JOB"
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

DEPOTSCRIPT=$(getDepotScriptLocationREL "$SCRIPT")
PROD_JOB="$(getJobLocationPROD "$SCRIPT")"
QA_JOB="$(getJobLocationQA "$SCRIPT")"
PROD_JOB="$(getJobLocationPROD "$SCRIPT")"
LLE_JOB="$(getJobLocationLLE "$SCRIPT")"
ENG_JOB="$(getJobLocationLLE "$SCRIPT")"

showparams

bl_conf_auto BL_ENG_PROFILE "$BL_ENG_PROFILE"

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

echo "==== START: adding QA ACL \"$BL_QA_TEMPLATE\" to script \"$DEPOTSCRIPT\" ===="
echo bl_applyAclTemplate --depotobject "$DEPOTSCRIPT" --acl "$BL_QA_TEMPLATE"
bl_applyAclTemplate --depotobject "$DEPOTSCRIPT" --acl "$BL_QA_TEMPLATE"
error_out $? "could not set ACL to \"$BL_QA_TEMPLATE\" on \"$DEPOTSCRIPT\""
echo "==== END: adding QA ACL \"$BL_QA_TEMPLATE\" to script \"$DEPOTSCRIPT\" ===="

touch "$PROMOTEFINISH"
ERR=$?
if test $ERR != 0; then
    error_out $ERR "ERROR: could not touch \"$PROMOTEFINISH\""
fi

#echo; echo;
#echo "==== START: getting perms on repromoted script \"$DEPOTSCRIPT\" ===="
#bl_showperm --depotobject "$DEPOTSCRIPT" > "$POST_REPROMOTE_PERMS"
#error_out $? "could not get perms on \"$DEPOTSCRIPT\""
#echo "==== END getting perms on repromoted script \"$DEPOTSCRIPT\" ===="
#
#export ERR_CNT=0
#grep -Pzo "^===+ RESULTS =+\n(.*\n)+?^Policy Name" "$PRE_DEMOTE_PERMS" | head -n -1  | tail -n +2 | while read perm
#do
#    echo checking $perm
#    if ! egrep "$perm" "$POST_REPROMOTE_PERMS"
#    then
#        echo "ERROR: \"$perm\" is missing in $POST_REPROMOTE_PERMS"        
#        ERR_CNT=$(($ERR_CNT+1))
#    fi
#done
#for policy in $(egrep "^Policy Name:" "$PRE_DEMOTE_PERMS" | awk '{ print $2 }')
#do
#    if ! egrep "^Policy Name: $policy$" "$POST_REPROMOTE_PERMS"
#    then
#        echo "$ERROR: policy \"$policy\" is missing in $POST_REPROMOTE_PERMS"
#        ERR_CNT=$(($ERR_CNT+1))
#    fi
#done
#
#error_out $ERR_CNT "$ERR_CNT permission errors were detected"
