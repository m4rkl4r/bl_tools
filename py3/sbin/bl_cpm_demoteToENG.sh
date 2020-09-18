#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh

SCRIPT="$1"

PROMOTESTART=".promoteToQA.started.$SCRIPT"
PROMOTEFINISH=".promoteToQA.finished.$SCRIPT"

function usage() {
        echo USAGE: $0 SCRIPT$
        echo$
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"$
        echo "USAGE: $0 SCRIPT"$
        echo ""
        echo "This will make the depotscript in BL_ENG_BASE/PREFIX"
        echo "readable by only ENG, effectively disabling all jobs"
        echo ""
        echo "PREFIX refers to the part of CWD that comes after BL_LOCAL_ENG but _before_ SCRIPT"$
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

bl_conf_auto BL_QA_PROFILE "$BL_QA_PROFILE"

#echo "==== START: capturing permissions on $DEPOTSCRIPT before demoting ===="
#bl_addperm --depotobject "$DEPOTSCRIPT" > ".perms.before.demote.$SCRIPT"
#bl_showperm --depotobject "$DEPOTSCRIPT" > ".perms.before.demote.$SCRIPT"
#error_out $? "could not capture permissions on $DEPOTSCRIPT"
#echo "==== END: capturing permissions on $DEPOTSCRIPT before demoting ===="

echo; echo
 #grep -Pzo "^===+ RESULTS =+\n(.*\n)+?^Policy Name" perms.txt
echo "==== START: setting ACL to \"$BL_ENG_TEMPLATE\" on script \"$DEPOTSCRIPT\" ===="
echo bl_applyAclTemplate --depotobject "$DEPOTSCRIPT" --acl "$BL_ENG_TEMPLATE" --replace
bl_applyAclTemplate --depotobject "$DEPOTSCRIPT" --acl "$BL_ENG_TEMPLATE" --replace
error_out $? "could not set ACL to \"$BL_ENG_TEMPLATE\" on \"$DEPOTSCRIPT\""
echo "==== END: setting ACL to \"$BL_ENG_TEMPLATE\" on script \"$DEPOTSCRIPT\" ===="

rm -f "$PROMOTESTART" && rm -f "$PROMOTEFINISH"
ERR=$?
if test $ERR != 0; then
    echo
    echo "WARNING: could not remove these:"
    ls -l "$PROMOTESTART" "$PROMOTEFINISH"
    exit
fi

#echo "==== setting ACL to \"$BL_ENG_TEMPLATE\" on job \"$LLE_JOB\" ===="
#echo bl_applyAclTemplate --jobobject "$LLE_JOB" --acl "$BL_ENG_TEMPLATE"
#bl_applyAclTemplate --jobobject "$LLE_JOB" --acl "$BL_ENG_TEMPLATE" --replace
#error_out $? "could not set ACL to \"$BL_ENG_TEMPLATE\" on \"$LLE_JOB\""
