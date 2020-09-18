. /unixworks/virtualenvs/py27/bin/activate
STORE_PS1="$PS1"
export PYTHONPATH=[paths to all your python libraries, including blBase and blLib]
export PATH=[adjust as needed.  include the bl_tools bin dir]
export BL_CONFDIR=~/.bl_tools/conf
export BL_LOCAL_ENG=/unixworks/bl_tools/eng
export BL_ENG_BASE=[ENG ROLE BASE PATH INSIDE BL]
export BL_QA_BASE=[QA ROLE BASE PATH INSIDE BL]
export BL_LLE_BASE=[LLE ROLE BASE PATH INSIDE BL]
export BL_PROD_BASE=[PROD ROLE BASE PATH INSIDE BL]
export BL_APP_LLE_BASE=[APP LLE BASE PATH INSIDE BL]
export BL_APP_PROD_BASE=[APP PROD BASE PATH INSIDE BL]
export BL_ENG_TEMPLATE=[ENG ACL TEMPLATE NAME]
export BL_QA_TEMPLATE=[QA ACL TEMPLATE NAME]
export BL_LLE_TEMPLATE=[LLE ACL TEMPLATE NAME]
export BL_PROD_TEMPLATE=[PROD ACL TEMPLATE NAME]
export BL_ENG_ROLE=[ENG ROLE NAME]
export BL_QA_ROLE=[QA ROLE NAME]
export BL_LLE_ROLE=[LLE ROLE NAME]
export BL_PROD_ROLE=[PROD ROLE NAME]
export BL_APP_LLE_ROLE=[APP LLE ROLE NAME]
export BL_APP_PROD_ROLE=[APP PROD ROLE NAME]

if test -f ~/.bl_tools/blvars.sh
then
. ~/.bl_tools/blvars.sh
fi

function bl_pass {
    echo -n "Password: "
    read -s BL_PASS
    BL_PASS=`bl_b64e $BL "$BL_PASS"`    
    export BL_PASS
    echo
}
export -f bl_pass


function getBlUser() {
    local CONF="$1"
    if test -z "$CONF" || test -z "$BL_CONF"
    then
        echo "getBlUser() requires BL_CONF env variable, or pass it as an argument."
        return 1
    fi
    if test -n "$BL_CONF"; then local CHKCONF="$BL_CONF"; fi
    if test -n "$CONF"; then local CHKCONF="$CONF"; fi
    grep blUser: "$BL_CONFDIR/$CHKCONF" | awk '{ print $2 }' | cut -f1 -d@
}
function isServiceAcct() {
    local USER="$1"
    if test -z "$USER"; then
        echo "USAGE: isServiceAccount USERNAME"
        return 1
    fi
    getent passwd "$USER" | grep -q "Type S,"
}
function error_out() {
    ERR="$1"
    MSG="$2"
    if test "$ERR" != 0
    then
            echo "ERROR: $MSG; EXITING ERR=$ERR"
            exit $ERR
    fi
}
function warn_out() {
    ERR="$1"
    MSG="$2"
    if test "$ERR" != 0
    then
        echo "WARNING: $MSG; ERR=$ERR"
    fi
}

function confPerm {
    local CONF=$1
    if ! test -O "$CONF"; then
        echo ERROR: $CONF is  not owned by `whoami`
        return 1
    fi
    
    local ACCESS=`stat $CONF | grep Access | grep Uid | awk -F/ '{ print $2 }' | cut -f1 -d\)`
    if echo $ACCESS | egrep -q "^....r" || echo $ACCESS | egrep -q "^.......r"
    then
        echo "ERROR: $CONF gives read access to group or all"
        return 1
    fi
    if echo $ACCESS | egrep -q "^.....w" || echo $ACCESS | egrep -q "^........w"
    then
        echo "ERROR: $CONF gives write access to group or all"
        return 1
    fi
    return 0
}
export -f confPerm

function bl_conf {
    local CONF=$1
    if test -n "$CONF" && ! ls $BL_CONFDIR | egrep "^${CONF}$" > /dev/null 2>&1
    then
        echo "Try again with valid role, or use no arguments to select"
        return 1
    fi
    if ! confPerm "$BL_CONFDIR/$CONF"
    then
        echo please fix permissions on $BL_CONFDIR/$CONF
        return 1
    fi
    
    if test -n "$CONF" &&  ls $BL_CONFDIR | egrep "^${CONF}$" > /dev/null 2>&1
    then
        true
    else
        echo "Choose one of:"
        ls $BL_CONFDIR | sed -e 's/^/    /'
        while ! ls $BL_CONFDIR | egrep "^${CONF}$" > /dev/null 2>&1
        do
            echo -n "CONF> "
            read CONF
            if [ "$CONF" = "exit" ]; then return; fi
        done
    fi
    myGroup=`cat "$BL_CONFDIR/$CONF" | egrep "^myGroup:" | sed -e 's/myGroup: //'`
    defaultMyGroup=`cat "$BL_CONFDIR/$CONF" | egrep "^defaultMyGroup:" | sed -e 's/^defaultMyGroup: //'`
    myRole=`cat "$BL_CONFDIR/$CONF" | grep blRole: | awk '{ print $2 }'`
    local base64Pass=`cat "$BL_CONFDIR/$CONF" | egrep blPass: | awk '{ print $2 }'`
    if test -n "$base64Pass"; then
        blUser=$(cat "$BL_CONFDIR/$CONF" | grep ^blUser: | awk '{ print $2 }' | cut -f1 -d@)
        if test -n "$blUser" && getent passwd $blUser | egrep -i ^$blUser | grep -q "Type S"
        then
                BL_PASS=$base64Pass
                export BL_PASS
        else
            echo blPass can only be stored for service accounts
            echo Please remediate $BL_CONFDIR/$CONF
        fi
    fi
    export myGroup
    export defaultMyGroup
    export myRole
    BL_CONF="$CONF"
    export BL_CONF
    echo BL_CONF SET is now set TO $BL_CONF, myGroup set TO $myGroup
    if test -z "$BL_PASS"; then
        echo "BL_PASS is not set.  please run bl_pass"
    fi
    PS1="$STORE_PS1($CONF:$myGroup \W) "
}
export -f bl_conf

function bl_mkconf {
    while echo -n "Profile Name - how to refer to this role when executing bl_conf - no whitespace: " &&  read profile_name
    do
        if ! echo $profile_name | egrep -q "\s" && echo $profile_name | grep -q "[a-zA-Z0-9]" && ! echo $profile_name | egrep -q "/"
        then
            break
        fi
    done
    while echo -n "Role Name: " && read role_name
    do
        if ! echo $role_name | egrep -q "\s" && echo $role_name | grep -q "[a-zA-Z0-9]"
        then
            break
        fi
    done

    while echo -n "User Name - like `echo $USER | tr a-z A-Z`@[AD DOMAIN HERE]: " &&  read user_name
    do
        if ! echo $user_name | egrep -q "\s" && echo $user_name | grep -q "[a-zA-Z0-9]"
        then
            break
        fi
    done

    FIRST=`getent passwd $USER | cut -f5 -d:|cut -f2 -d\ |tr A-Z a-z`
    LAST=`getent passwd $USER | cut -f5 -d:| awk '{ print $1 }' | sed -e 's/,//' | tr A-Z a-z`
    if test -n "$FIRST" || test -z "$LAST"
    then
        EXAMPLE_NAME="${FIRST}-${LAST}"
    else
        EXAMPLE_NAME="bender-rodriguez"
    fi

    while echo -n "Default Location - where your scripts and jobs will be kept - like /WorkAreas/$role_name/$USER-$EXAMPLE_NAME - whitespace discouraged: " &&  read group_name
    do
        if echo $group_name | grep -q "[a-zA-Z0-9]"
        then
            break
        fi
    done

    mkdir -p $BL_CONFDIR
    echo overwriting $BL_CONFDIR/$profile_name
    {
    echo \[Bladelogic\]
    echo blRole: $role_name
    echo blUser: $user_name
    echo passType: ADK_PASSWORD
    echo myGroup: $group_name
    echo defaultMyGroup: $group_name
    echo serverGroup: /Servers by Role/$role_name
    echo loginUrl: https://[BL UI SERVER]:10003/services/LoginService?wsdl
    echo roleUrl: https://[BL UI SERVER]:10003/services/AssumeRoleService?wsdl
    echo cliUrl:  https://[BL UI SERVER]:10003/services/CLITunnelService?wsdl
    } > "$BL_CONFDIR/$profile_name"
    chmod 600 "$BL_CONFDIR/$profile_name"
    chmod 700 "$BL_CONFDIR"
}
export -f bl_mkconf
        
function bl_chdir {
    local newGrp=
    if test "$1" == "--help"
    then
        echo USAGE: bl_chdir "/the new/path"
        echo USAGE: bl_chdir
        echo 'bl_chdir sets the "working directory" to search for bl scripts jobs and servers'
        echo 'by editing myGroup;  $myGroup will be edited in the current shell environment and myGroup will be updated in the conf file.'
        return 1
    elif test -z "$BL_CONF"; then
        echo "please run bl_conf to set the current profile"
        return 1
    elif echo "$1" | egrep -q "^\.\.$|^\.\./"
    then
        echo "Sorry, \"bl_chdir ..\" is not supported yet"
    elif test -n "$1" && ! echo $1 | egrep -q "^/"
    then
        if echo $1 | egrep -v "^\./"
        then
            newGrp="$myGroup/$1"
        else
            newGrp="$myGroup/${1:2:${#2}}"
        fi
    elif test -n "$1"
    then
       newGrp="$1"
       if test ${#newGrp} -gt 1 && test ${newGrp:${#newGrp}-1:1} = "/"
       then
          newGrp=${newGrp:0:${#newGrp}-1}
       fi
    fi
    if test -z "$newGrp"; then
        echo starting with profile "$BL_CONF" and \$myGroup=$myGroup
        echo -n "new value for myGroup[$defaultMyGroup]: "
        read newGrp
        if test -z "$newGrp";
        then
            newGrp="$defaultMyGroup"
        fi
    fi
    ## escape the baclslashes in $newGrp for the next operation
    cat "$BL_CONFDIR/$BL_CONF" | egrep -v "^myGroup:" > "$BL_CONFDIR/${BL_CONF}.tmp" && echo "myGroup: $newGrp" >> "$BL_CONFDIR/${BL_CONF}.tmp" && mv "$BL_CONFDIR/${BL_CONF}.tmp" "$BL_CONFDIR/${BL_CONF}"
    chmod 600 "$BL_CONFDIR/$BL_CONF"
    if [ $? = 0 ]; then 
        bl_conf $BL_CONF
    else
        echo chdir failed
        return 1
    fi
    PS1="$STORE_PS1($BL_CONF:$myGroup \W) "
    return 0
}
export -f bl_chdir

function getBase() {
    local BL_BASE=
    if test -z "$myRole"; then
        echo "\$myRole is undefined.  please set ENV with bl_conf" 
        return 1
    elif test $myRole = [ENG ROLE NAME]
    then
        BL_BASE=$BL_ENG_BASE
    elif test $myRole = [QA ROLE NAME]
    then
        BL_BASE=$BL_QA_BASE
    elif test $myRole = [NP ROLE NAME]
    then
        BL_BASE=$BL_LLE_BASE
    elif test $myRole = [PROD ROLE NAME]
    then
        BL_BASE=$BL_PROD_BASE
    else
        echo "\$myRole=\"$myRole\" is not set to a valid role.  please bl_conf to a valid role."
        return 1
    fi
    echo $BL_BASE
    return 0
}
function getSuffix() {
    ## env var $myGroup is like CWD for bladelogic scripts and jobs.
    ## getSuffix() gets the base BL group for the current role, subtracts that from the
    ## beginning of $myGroup, and returns the result
    local SUFFIX=
    local BASE="$(getBase)"
    ERR=$?
    if test $ERR != 0; then
        echo "getSuffix: getBase failed."
        return $ERR
    fi
    if test -z "$myGroup"; then
        echo "\$myGroup is undefined.  please set ENV with bl_conf."
        return 1
    fi
    SUFFIX="$(echo $myGroup | sed -e "s#$BASE/##")" 
    if echo $SUFFIX | egrep -q ^/
    then
        echo SUFFIX=$SUFFIX
        echo "ERROR: getSuffix requires myGroup=\"$myGroup\" to be a subgroup of \"$BASE\", the BL group corresponding to the current BL role"
        return 1
    fi
    echo $SUFFIX
    return 0
}
    
function getPrefix() {
    ## like calling dirname on a file in CWD, then removing $BL_LOCAL_ENG from the result
    ## So if BL_LOCAL_ENG=/unixworks/bl_tools/eng, 
    ## and we are in /unixworks/bl_tools/eng/some/script/dir,
    ## then getPrefix() will return some/script/dir

    if test "$(pwd)" == "$BL_LOCAL_ENG"
    then
        PREFIX=
    else
        PREFIX=`pwd | sed -e "s#^$BL_LOCAL_ENG/##"`
        if test "$PREFIX" = "`pwd`" && test "$PREFIX" != "$BL_LOCAL_ENG"
        then
            echo ERROR: getPrefix requires CWD to be located in BL_LOCAL_ENG=\"$BL_LOCAL_ENG\"
            echo 
            echo RETURNING 1
            return 1
        fi
    fi
    echo $PREFIX
    return 0
}

#if test -d $BL_CONFDIR
#then
#    for conf in `ls $BL_CONFDIR`
#    do
#            GRP=`egrep "^myGroup:" $BL_CONFDIR/$conf | awk '{ print $2 }'`
#            GRPVAR=myGroup_$conf
#            export ${GRPVAR}=$GRP
#    done
#fi

function listify {
    LIST="$*"
    LIST=`echo $LIST | sed -e 's/ \+/,/g'`
    echo $LIST
}
function listify_f {
    FILE=$1
    listify `cat $FILE`
}
function spacify {
    LIST=$*
    LIST=`echo $LIST | sed -e 's/,/ /g'`
    echo $LIST
}
function spacify_f {
    F=$1
    LIST=`cat $F|egrep -v ^$|sed -e 's/^( \|    )\+//' -e 's/*( \|    )*$//'`
    echo $LIST
}
function sniqify { # do tr A-Z a-z | sort | uniq on file and replace
    FILE="$1"
    wc -l "$FILE"
    cat "$FILE" | tr A-Z a-z | sort | uniq|egrep -v "^$" > /tmp/file.$$
    mv /tmp/file.$$ "$FILE"
    wc -l "$FILE"
}
function pipeify {
    LIST="$*"
    LIST=`echo $LIST | sed -e 's/ \+/|/g'`
    echo $LIST
}

function bl_time_et_now_plus_minutes {
    SECONDS=$(($1 * 60))
    TZ=America/New_York date "+%Y-%m-%d %H:%M:%S" --date=@$(($(date +%s)+$SECONDS))
}
shopt -s checkwinsize

function bl_cpm_chgrp() {
    if test $# != 0;
    then
        echo USAGE: bl_cpm_chgrp
        echo if env is configured using bl_conf, and CWD is contained in BL_LOCAL_ENG=$BL_LOCAL_ENG,
        echo "(where the job definition folders are),"
        echo "then \$myGroup will be set to /WorkAreas/\$myRole/\$PREFIX,"
        echo "where PREFIX is the current subdirectory inside BL_LOCAL_ENG"
        echo "and \$myRole is the BL role set by the bl_conf command."
        return 1
    fi
    PREFIX=$(getPrefix)
    ERR=$?
    if test $ERR != 0; then
        echo "ERROR: before executing bl_cpm_chgrp again,"
        echo "ERROR: please make sure you have set your env with bl_conf,"
        echo "ERROR: and then cd into a job definition folder in BL_LOCAL_ENG=$BL_LOCAL_ENG"
        return $ERR
    else
        bl_chdir "/WorkAreas/$myRole/$PREFIX"
    fi
}
function bl_cpm_chdir() {
    # examine $myGroup and determine how this maps into the local filesystem under BL_LOCAL_ENG
    # then, cd BL_LOCAL_ENG/SUFFIX
    SUFFIX="$(getSuffix)"
    ERR=$?
    if test $ERR != 0; then
        echo "ERROR: bl_cpm_chdir: getSuffix failed."
        return 1
    fi
    cd "$BL_LOCAL_ENG/$SUFFIX"
}
XDG_CONFIG_DIRS=/unixworks/bl_tools/etc
