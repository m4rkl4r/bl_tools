#!/bin/bash
. /unixworks/bl_tools/etc/promotion.sh
bl_conf_auto BL_ENG_PROFILE "$BL_ENG_PROFILE"
SCRIPT="$1"
ADDSCRIPT_PARAM="$2" # this should be --once, --each, --perl, --nexec (default)

if test -f ~/.bl_tools/blvars.sh
then
    . ~/.bl_tools/blvars.sh
fi

function usage() {
        echo USAGE: $0 SCRIPT \[ADDSCRIPT_PARAM\]
        echo
        echo update bladelogic script and job depots for ENG role
        echo
        echo BL_LOCAL_ENG=\"$BL_LOCAL_ENG\" is defined in /unixworks/bl_tools/etc/bl_tools.sh
        echo It can also be defined in ~/.bltools/blvars.sh
        echo
        echo PREFIX is is the remainder when you subtract BL_LOCAL_ENG from CWD
        echo So, if CWD=$BL_LOCAL_ENG/util/passwd, then PREFIX=util/password
        echo
        echo SCRIPT is the script/jobname being updated
        echo SCRIPT must live in CWD, which must be in \$BL_LOCAL_ENG/\$PREFIX - see below
        echo 
        echo ADDSCRIPT_PARAM is required unless its defined on a single line in
        echo  \$BL_LOCAL_ENG/\$PREFIX/scripttype/script_title, where script_tile is the script 
        echo name with the version number and .sh or .nsh suffix removed
        echo
        echo ADDSCRIPT_PARAM is applied to the NSHScript, and should be one of:
        echo "   --once (execute once, with hostlist passed using %h),"
        echo "   --each (run once on each host, as bladmin),"
        echo "   --perl,"
        echo "   --nexec (for non-nsh, i.e. bash etc, as root)"
        echo
        echo SCRIPT should be located at \$BL_LOCAL_ENG/\$PREFIX/\$SCRIPT
        echo
        echo "Jobs and scripts will be placed in BL_ENG_BASE/PREFIX"
        echo BL_ENG_BASE=\"$BL_ENG_BASE\" is defined in bl_tools.sh
        echo
        echo script/job parameters are defined in PREFIX/params/params.script_title.ENG.txt
        echo where script_title is the script name minus any sh/nsh suffix
        echo
        echo each line of the param file has three parameters, plus one optional:
        echo "  PARAMNAME PARAMVAL DESCRIPTION [PARAMOPT]"
        echo
        echo PARAMOPT is applied to script parameters, and is a some of these numbers:
        echo "   1 = takes value 2 = not empty 4 = editable 8 = param flag required"
}

function showparams() {
    echo "==== START PARAMETERS ===="
    echo PREFIX=$PREFIX
    echo SCRIPT=$SCRIPT
    echo PARAMFILE_ENG=$PARAMFILE_ENG
    echo LOCALSCRIPT=$LOCALSCRIPT
    echo DEPOTSCRIPT=$DEPOTSCRIPT
    echo DEPOTGROUP=$DEPOTGROUP
    echo JOB_ENG=$JOB_ENG
    echo JOBGROUP_ENG=$JOBGROUP_ENG
    echo ADDSCRIPT_PARAM=$ADDSCRIPT_PARAM
    echo HOSTLIST_ENG=$HOSTLIST_ENG
    echo "==== END PARAMETERS ===="
    echo
    if test -z "$PREFIX" || test -z "$SCRIPT" || test -z "$PARAMFILE_ENG" || test -z "$LOCALSCRIPT" || \
       test -z "$DEPOTSCRIPT" || test -z "$DEPOTGROUP" || test -z "$JOB_ENG" || test -z "$JOBGROUP_ENG" || \
       test -z "$ADDSCRIPT_PARAM" || test -z "$HOSTLIST_ENG"
    then
        error_out 1 "a variable was left undefined in showparams"
    fi
}
if test "$SCRIPT" == "--help" || test "$SCRIPT" == "-h"
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

## check for valid input for ADDSCRIPT_PARAM
if test -n "$ADDSCRIPT_PARAM" && ! echo "$ADDSCRIPT_PARAM" | egrep -q "^--(once|each|perl|nexec)$"
then
        usage
        echo
        echo ERROR: ADDSCRIPT_PARAM is specified it must bev one of --once, --each, --perl, --nexec
        exit 1
elif test -z "$ADDSCRIPT_PARAM" 
then
    ADDSCRIPT_PARAM=$(getScriptType "$SCRIPT")
fi
if test -z "$ADDSCRIPT_PARAM"
then
    usage
    echo
    echo ADDSCRIPT_PARAM must be defined on the commandline or in scripttype/script_title
    exit 1
fi
PARAMFILE_ENG="$(getParamFileENG "$SCRIPT")"
warn_out $? "PARAMFILE_ENG not found."
LOCALSCRIPT=`pwd`/`basename "$SCRIPT"`
DEPOTSCRIPT="$(getDepotScriptLocationDEV "$SCRIPT")"
DEPOTGROUP="$(dirname "$DEPOTSCRIPT")"
JOB_ENG="$(getJobLocationENG "$SCRIPT")"
JOBGROUP_ENG="$(dirname "$JOB_ENG")"
HOSTLIST_ENG="$(getHostlistFileENG "$SCRIPT")"
warn_out $? "ENG hostlist not found."

showparams

if test -z "$BL_ENG_BASE"
then
    echo BL_ENG_BASE is undefined.  Check /unixworks/bl_tools/etc/promotion.sh
    echo EXITING 1
    exit 1
fi


echo ==== end switching bl profile ====

echo "==== starting from scratch - deleting old job ===="
bl_deljob --job "$JOB_ENG"
warn_out $? "could not delete job \"$JOB_ENG\""
echo ; echo; echo

echo "==== starting from scratch - deleting old script ===="
bl_delscript --depotscript "$DEPOTSCRIPT"
warn_out $? "could not delete script \"$DEPOTSCRIPT\""
echo ; echo; echo

echo "==== creating depotgroup if needed: \"$DEPOTGROUP\" ===="
bl_mkdir --depotgroup "$DEPOTGROUP"
error_out $? "depot group creation failed for \"$DEPOTGROUP\""
echo ; echo; echo

echo "==== creating jobgroup if needed: \"$JOBGROUP_ENG\" ===="
bl_mkdir --jobgroup "$JOBGROUP_ENG"
error_out $? "job group creation failed for \"$JOBGROUP_ENG\""
echo ; echo; echo

echo "==== uploading script \"$LOCALSCRIPT\" to depot at \"$DEPOTSCRIPT\" ===="
bl_addscript --script "$LOCALSCRIPT" --depotscript "$DEPOTSCRIPT" $ADDSCRIPT_PARAM
error_out $? "script \"$LOCALSCRIPT\" could not upload to depot at \"$DEPOTSCRIPT\"."
echo ; echo; echo

echo "==== adding parameters to script \"$DEPOTSCRIPT\" ===="
add_script_params "$PARAMFILE_ENG" "$DEPOTSCRIPT"
error_out $? "could not add params to script \"$DEPOTSCRIPT\"."
echo ; echo; echo

echo "==== creating job \"$JOB_ENG\" from depot script \"$DEPOTSCRIPT\" ===="
bl_addjob  --depotscript "$DEPOTSCRIPT" --job "$JOB_ENG" $PARALLELIZE
error_out $? "could not create job \"$JOB_ENG\" from \"$SCRIPT_DESTIONATION.\""
echo; echo; echo

echo "==== adding parameters to job \"$JOB_ENG\" ===="
add_job_params "$PARAMFILE_ENG" "$JOB_ENG"
error_out $? "could not add params to job \"$JOB_ENG\"."
echo; echo; echo

echo "==== adding hosts in $HOSTLIST_ENG to job \"$JOB_ENG\" ===="
if test -n "$HOSTLIST_ENG" 
then
    bl_job_addservers --job "$JOB_ENG" --serverfile "$HOSTLIST_ENG"
    warn_out $? "echo could not add servers in $HOSTLIST_ENG to job \"$JOB_ENG\"."
fi
echo; echo; echo
