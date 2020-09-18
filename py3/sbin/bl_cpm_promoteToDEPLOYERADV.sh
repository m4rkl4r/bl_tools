#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh
SCRIPT="$1"

function usage() {
        echo USAGE: $0 SCRIPT$
        echo$
        echo "After cd'ing into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG,"$
        echo "USAGE: $0 SCRIPT"$
        echo ""
        echo "This will make the script located at:"
        echo "  BL_ENG_BASE/PREFIX/rel/SCRIPT"
        echo "available to DEPLOYERADV_NP and DEPLOYERADV_PROD roles, and restrict"
        echo "ENG and QA roles to read access"
        echo ""
        echo "PREFIX refers to the part of CWD that comes after BL_LOCAL_ENG but _before_ SCRIPT"$
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
    echo BL_QA_PROFILE=$BL_QA_PROFILE
    echo BL_QA_ROLE=$BL_QA_ROLE
    echo "==== STOP PARAMETERS ===="
    echo
    if test -z "$PREFIX" || test -z "$PREFIX_REL" || test -z "$PREFIX_DEV" || test -z "$SCRIPT" || \
       test -z "$DEPOTSCRIPT_DEV" || test -z "$DEPOTSCRIPT_REL" || test -z "$DEPOTGROUP_DEV" || \
       test -z "$DEPOTGROUP_REL" || test -z "$BL_QA_PROFILE" || test -z "$BL_QA_ROLE"
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

PREFIX_REL="$PREFIX/rel"
PREFIX_DEV="$PREFIX/dev"
DEPOTSCRIPT_DEV="$(getDepotScriptLocationDEV "$SCRIPT")"
DEPOTSCRIPT_REL="$(getDepotScriptLocationREL "$SCRIPT")"
DEPOTGROUP_DEV="$(dirname "$DEPOTSCRIPT_DEV")"
DEPOTGROUP_REL="$(dirname "$DEPOTSCRIPT_REL")"
LLE_JOB="$(getJobLocationLLE "$SCRIPT")"
LLE_JOBGROUP="$(dirname "$LLE_JOB")"
LLE_PARAMFILE="$(getParamFileLLE "$SCRIPT")"
PROD_JOB="$(getJobLocationPROD "$SCRIPT")"
PROD_JOBGROUP="$(dirname "$PROD_JOB")"
PROD_PARAMFILE="$(getParamFilePROD "$SCRIPT")"

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

bl_conf_auto BL_QA_PROFILE "$BL_QA_PROFILE"

echo "==== Locking down perms on DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL ===="
echo "===== setting ACL on DEPOTSCRIPT_REL=$DEPOTSCRIPT_REL to \"$BL_LLE_TEMPLATE\" ====="
bl_applyAclTemplate --depotobject "$DEPOTSCRIPT_REL" --acl "$BL_LLE_TEMPLATE" --replace
error_out $? "couldn't set ACL to \"$BL_LLE_TEMPLATE\" on \"$DEPOTSCRIPT_REL\""
echo; echo; echo
echo "===== adding ACL  \"$BL_PROD_TEMPLATE\" to DEPOTSCRIPT_REL=\"$DEPOTSCRIPT_REL\" ====="
bl_applyAclTemplate --depotobject "$DEPOTSCRIPT_REL" --acl "$BL_PROD_TEMPLATE"
error_out $? "couldn't add ACL \"$BL_PROD_TEMPLATE\" to \"$DEPOTSCRIPT_REL\""
echo; echo; echo
echo "===== giving \"$BL_ENG_ROLE\" NSHScript.Read on \"$DEPOTSCRIPT_REL\" ====="
bl_addperm --depotobject "$DEPOTSCRIPT_REL" --role "$BL_ENG_ROLE" --authname NSHScript.Read
error_out $? "couldnt give NSHScript.Read to \"$BL_ENG_ROLE\" on script \"$DEPOTSCRIPT_REL\""
echo; echo; echo
echo "===== giving \"$BL_QA_ROLE\" NSHScript.Read on \"$DEPOTSCRIPT_REL\" ====="
bl_addperm --depotobject "$DEPOTSCRIPT_REL" --role "$BL_QA_ROLE" --authname NSHScript.Read
error_out $? "couldnt give NSHScript.Read to \"$BL_QA_ROLE\" on script \"$DEPOTSCRIPT_REL\""
echo; echo; echo
