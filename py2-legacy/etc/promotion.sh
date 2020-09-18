. /unixworks/bl_tools/etc/bl_tools.sh

if test -z "$BL_LOCAL_ENG"
then
    echo BL_LOCAL_ENG must be defined before sourcing promotion.sh
    help
    exit 1
fi
if test -z "$BL_PASS"
then
    echo "please run bl_pass; EXITING 1."
    exit 1
fi

function assertScriptInCWD() {
    local SCRIPT="$1"
    if test "`dirname \"$SCRIPT\"`" != "." || ! test -f "$SCRIPT"
    then
        usage
        echo
        echo ERROR: SCRIPT \"$SCRIPT\" is not in CWD or does not exist.  EXITING 1
        exit 1
    fi
    return 0
}
function assertScriptSuffix() {
    local SCRIPT="$1"
    local SHELL=$(echo $SCRIPT |  awk -F\. '{ print $NF }')
    local VERSION=$(echo $SCRIPT |  awk -F\. '{ print $(NF-1) }')
    if ! echo $VERSION | egrep -q "^[0-9]+$"
    then
        error_out $? "for SCRIPT=\"$SCRIPT\", VERSION=$VERSION is not a non-negative integer"
    elif ! echo $SHELL | egrep -q "^(nsh|sh)$" 
    then
        error_out $? "for SCRIPT=\"$SCRIPT\", suffix SHELL=\"$SHELL\" is not nsh or sh"
    fi
    return 0
}

#function getPrefix() {
#    if test "$(pwd)" == "$BL_LOCAL_ENG"
#    then
#        PREFIX=
#    else
#        PREFIX=`pwd | sed -e "s#$BL_LOCAL_ENG/##"`
#        if test "$PREFIX" = "`pwd`" && test "$PREFIX" != "$BL_LOCAL_ENG"
#        then
#            echo ERROR: getPrefix requires CWD to be located in BL_LOCAL_ENG=\"$BL_LOCAL_ENG\"
#            echo 
#            echo EXITING 1
#            exit 1
#        fi
#    fi
#    echo $PREFIX
#}
function getBasicScriptName() {
    # get script name without type suffix and version number
    local LOCALSCRIPT=$(basename "$1")
    if echo $LOCALSCRIPT | egrep -q "\.(nsh|sh)$"
    then
        LOCALSCRIPT=`echo $LOCALSCRIPT | sed -e 's/\.n\?sh$//'`
    fi
    if echo $LOCALSCRIPT | egrep -q "\.[0-9]+"
    then
        LOCALSCRIPT=`echo $LOCALSCRIPT | sed -e 's/\.[0-9]\+$//'`
    fi
    echo $LOCALSCRIPT
}
function getParallelizeFileName() {
    local LOCALSCRIPT="$(getBasicScriptName "$1")"
    echo "$BL_LOCAL_ENG/$(getPrefix)/parallelize/$LOCALSCRIPT"
}
function getParallelize() {
    local FNAME="$(getParallelizeFileName "$1")"
    cat "$FNAME"
}
function assertParallelize() {
    P="$(getParallelize "$1")"
    if echo $P | egrep -q "^$" || echo $P | egrep -q "^[0-9]+"
    then
        return 0
    else
        error_out $? "$(getParallelizeFileName "$1") must contain a positive integer"
    fi
}
function _getHostlistFileName() {
    local LOCALSCRIPT="$(getBasicScriptName "$1")"
    echo "$BL_LOCAL_ENG/$(getPrefix)/hostlist/hostlist.$LOCALSCRIPT"
}
function getHostlistFileENG() {
    local LOCALSCRIPT="$1"
    ls $(_getHostlistFileName "$LOCALSCRIPT").ENG
    return $?
}
function getHostlistFileQA() {
    local LOCALSCRIPT="$1"
    ls $(_getHostlistFileName "$LOCALSCRIPT").QA
    return $?
}
function getHostlistFileLLE() {
    local LOCALSCRIPT="$1"
    ls $(_getHostlistFileName "$LOCALSCRIPT").LLE
    return $?
}
function getHostlistFilePROD() {
    local LOCALSCRIPT="$1"
    ls $(_getHostlistFileName "$LOCALSCRIPT").PROD
    return $?
}
function getScriptTypeName() {
    local LOCALSCRIPT="$(getBasicScriptName "$1")"
    local PREFIX=$(getPrefix)
    local JOBTYPEFILE="$BL_LOCAL_ENG/$PREFIX/scripttype/$LOCALSCRIPT"
    echo "$JOBTYPEFILE"
}

function getScriptType() {
    local SCRIPTTYPE=$(getScriptTypeName "$1")
    cat "$SCRIPTTYPE"
}

function _getParamFileName() {
    local LOCALSCRIPT="$(getBasicScriptName "$1")"
    local PREFIX=$(getPrefix)
    local PARAMFILE=$BL_LOCAL_ENG/$PREFIX/params/params.$LOCALSCRIPT
    echo $PARAMFILE
}
function getParamFileQA() {
    local LOCALSCRIPT="$1"
    ls $(_getParamFileName "$LOCALSCRIPT").QA
    return $?
}
function getParamFileENG() {
    local LOCALSCRIPT="$1"
    ls $(_getParamFileName "$LOCALSCRIPT").ENG
    return $?
}
function getParamFileLLE() {
    local LOCALSCRIPT="$1"
    ls $(_getParamFileName "$LOCALSCRIPT").LLE
    return $?
}
function getParamFilePROD() {
    local LOCALSCRIPT="$1"
    ls $(_getParamFileName "$LOCALSCRIPT").PROD
    return $?
}

# not for direct use
function _getDepotScriptLocation() {
    local PREFIX=$(getPrefix)
    local LOCATION="$BL_ENG_BASE"
    if test -n "$PREFIX"; then
        LOCATION="$LOCATION/$PREFIX"
    fi
    echo $LOCATION
}
    
function getDepotScriptLocationDEV() {
    local SCRIPT="$1"
    echo "$(_getDepotScriptLocation)/dev/$1"
}
function getDepotScriptLocationREL() {
    local SCRIPT="$1"
    echo "$(_getDepotScriptLocation)/rel/$1"
}
function getJobLocationENG() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_ENG_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo $GROUP/$(basename "$SCRIPT")
}
function getJobLocationQA() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_QA_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo $GROUP/$(basename "$SCRIPT")
}
function getJobLocationLLE() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_LLE_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo "$GROUP/$(basename "$SCRIPT")"
}
function getJobLocationPROD() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_PROD_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo "$GROUP/$(basename "$SCRIPT")"
}
function getJobLocationAPPLLE() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_APP_LLE_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo "$GROUP/$(basename "$SCRIPT")"
}
function getJobLocationAPPPROD() {
    local SCRIPT="$1"
    local PREFIX=$(getPrefix)
    local GROUP="$BL_APP_PROD_BASE"
    if test -n "$PREFIX"
    then
        GROUP="$GROUP/$PREFIX"
    fi
    echo "$GROUP/$(basename "$SCRIPT")"
}
function add_script_params() {
    local PARAMFILE="$1"
    local SCRIPT_DESTINATION="$2"
    if test -n "$PARAMFILE" && test -f "$PARAMFILE"
    then
        echo "adding parameters to script $SCRIPT_DESTINATION with empty values, from \"$PARAMFILE\""
        while read LINE
        do
            if echo "$LINE" | egrep -q "^\s+$|^#|^$"
            then
                continue
            fi
            declare -a local PARAMS="($LINE)"
            local PARAMNAME="${PARAMS[0]}"
            local PARAMVAL="${PARAMS[1]}"
            local DESCRIPTION="${PARAMS[2]}"
            local PARAMOPT=${PARAMS[3]}
            if test -n "$PARAMOPT"
            then
                PARAMOPT="--options $PARAMOPT"
            fi
            echo bl_param_add_nshscript --depotscript "$SCRIPT_DESTINATION" --name "$PARAMNAME" --value "$PARAMVAL" --desc "$DESCRIPTION" $PARAMOPT
            bl_param_add_nshscript --depotscript "$SCRIPT_DESTINATION" --name "$PARAMNAME" --value "$PARAMVAL" --desc "$DESCRIPTION" $PARAMOPT
            if [ $? != 0 ]; then
                echo "ERROR: failed to add parameters to script.  EXITING 1";
                exit 1
            fi
            echo ====
        done < "$PARAMFILE"
        echo parameters were added to $SCRIPT_DESTINATION
    else
        echo parameters were NOT added to \"$SCRIPT_DESTINATION\"
        echo either PARAMFILE was not set or PARAMFILE=\"$PARAMFILE\" was not found
    fi
}

function add_job_params() {
    local PARAMFILE="$1"
    local JOB_DESTINATION="$2"
    if test -n "$PARAMFILE"
    then
        local INDEX=0
        echo "adding parameter values to job \"$JOB_DESTINATION\", from \"$PARAMFILE\""
        while read LINE
        do
            if echo "$LINE" | egrep -q "^\s+$|^#|^$"
            then
                continue
            fi
            declare -a local PARAMS="($LINE)"
            local PARAMNAME="${PARAMS[0]}"
            local PARAMVAL="${PARAMS[1]}"
            local DESCRIPTION="${PARAMS[2]}"
            echo setting \"$PARAMNAME\" to \"$PARAMVAL\" on job \"$JOB_DESTINATION\"
            bl_param_addvalue_nshscriptjob --job "$JOB_DESTINATION" --index "$INDEX" --value "$PARAMVAL"
            if [ $? != 0 ]; then
                echo "ERROR: failed to add parameters to job. INDEX=$INDEX. EXITING 1";
                exit 1
            fi
            INDEX=$((INDEX+1))
            echo ====
        done < "$PARAMFILE"
    else
        echo parameters were added to $SCRIPT_DESTINATION
    fi
}

function traverse_apply_acl_template() {
    ## when doing mkdir into another role, apply that role's acl

    ## BASE is the base directory (i.e. group) for the role, content,
    ## like /WorkAreas/$ROLE_NAME
    local BASE="$1"
    ## directory structure in BASE to modify
    local THEREST="$2"
    ## ACL is the name of the acl template, typically named after the role
    local ACL="$3"
    ## TYPE is the group type, either "job" or "depot"
    local TYPE="$4"
    if ! (test "$TYPE" = "job" || test "$TYPE" = "depot")
    then
        echo ERROR: traverse_prefix_apply_acl arg3 must be "job" or "depot"
        echo EXITING 1
        exit 1
    fi
    OLDIFS="$IFS"
    IFS=/
    local WHERE="$BASE"
    for NEXT in $THEREST
    do
        WHERE="$WHERE/$NEXT"
        IFS="$OLDIFS"
        echo ===== apply \"$ACL\" to depot \"$WHERE\" =====
        echo bl_applyAclTemplate --${TYPE}object $WHERE --acl $ACL
        bl_applyAclTemplate --${TYPE}object $WHERE --acl $ACL
        error_out $? "could not apply acl \"$ACL\" to depot \"$WHERE\"."
        IFS="$NEWIFS"
    done
    IFS="$OLDIFS"
}
function traverse_apply_perm() {
    if test $# != 5
    then
        echo usage: travers_apply_perm BASEDIR JOBDIR PERM ROLE TYPE
        return 1
    fi
    ## when you need to give a perm to each folder in a path
    ## BASE is the base directory (i.e. group) for the role, content,
    ## like /WorkAreas/$ROLE_NAME
    local BASE="$1"
    ## directory structure in BASE to modify
    local GROUPDIR="$2"
    ## ACL is the name of the acl template, typically named after the role
    local PERM="$3"
    ## which role to give the perm to
    local ROLE="$4"
    ## TYPE is the group type, either "job" or "depot"
    local TYPE="$5"
    echo traverse_apply_perm BASE=$BASE GROUPDIR=$GROUPDIR PERM=$PERM ROLE=$ROLE TYPE=$TYPE
    if ! (test "$TYPE" = "job" || test "$TYPE" = "depot")
    then
        echo ERROR: traverse_apply_perm arg5 must be "job" or "depot", not \"$TYPE\"
        echo EXITING 1
        exit 1
    fi
    OLDIFS="$IFS"
    IFS=/
    local WHERE="$BASE"
    for NEXT in $GROUPDIR
    do
        IFS="$OLDIFS"
        WHERE="$WHERE/$NEXT"
        echo ===== apply \"$PERM\" to \"${TYPE}\"group \"$WHERE\" for role \"$ROLE\" =====
        echo bl_addperm --${TYPE}object $WHERE --role $ROLE --authname $PERM
        bl_addperm --${TYPE}object $WHERE --role $ROLE --authname $PERM
        error_out $? "ould not apply \"$PERM\" to \"${TYPE}\"group \"$WHERE\" for role \"$ROLE\""
        IFS="$NEWIFS"
    done
    IFS="$OLDIFS"
}

function bl_conf_auto() {
    ## for diagnostic purposes, pass in the variable name and then its contents
    ## like: bl_conf_auto "BL_ENG_PROFILE" "$BL_ENG_PROFILE"$
    local PROFILE_VAR="$1"
    local PROFILE="$2"
    echo bl_conf_auto: PROFILE_VAR=\"$PROFILE_VAR\" gives PROFILE=\"$PROFILE\"
    if test -n "$PROFILE"
    then
        echo bl_conf "$PROFILE"
        bl_conf "$PROFILE"
        while test -z "$BL_PASS"
        do
            echo RUNNING bl_pass for "$PROFILE:"
            bl_pass
        done
    else
        error_out 1 "please set and export $PROFILE_VAR in ~/.bl_tools/blvars.sh"
    fi
}
