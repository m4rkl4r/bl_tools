# created by mark price, starting Feb 2018
# 2019-07-19 - added setLogHost_PROD_OR_LLE - to set loghost based on lane.  
#              If loghost changes, this lets us edit just setup.sh rather than all the jobs
# 2019-07-19 - instead of defining TEE=tee -a $LOGFILE, just define LOGFILE, which is /dev/null if setLogHost fails
# 2019-07-20 - added once_setup_host, once_teardown_host, for run-once scripts
# 2019-07-20 - CHKAGENTLOG is transparently created to reference LOGDIR, tested for writes, and passed to chkagent
# 2019-08-01 - add SETUP_VERSION var
# 2019-08-01 - add function source_header
# 2019-08-01 - add function two_empty_lines
# 2019-09-14 - converted tabs to 4 spaces
# 2019-09-11 - add function empty_line, and removed all calls to two_empty_lines or empty_line from this header
# 2019-09-11 - assertLinux exits via cleanup
# 2019-10-17 - move prod loghost to afyxh

SETUP_VERSION=1

SHORT_NSH_RUNCMD_HOST=`echo $NSH_RUNCMD_HOST | cut -f1 -d.`


function setLogHost_PROD_OR_LLE() {
    local LANE="$1"
    if [ "$LANE" = "LLE" ]; 
    then
        LOGHOST=[lle.log.com]
    elif [ "$LANE" = "PROD" ]; then
        LOGHOST=[prod.log.com]
    else
        echo "setLogHost_PROD_OR_LLE: Could not set loghost - only LLE and PROD are valid arguments"
        return 1
    fi
    export LOGHOST
    echo LOGHOST=$LOGHOST
    return 0
}
function found_setup() {
    true
}

function chkagent {
    local HOST=$1
    local LOGFILE="$CHKAGENTLOG"

    ERR=
    if [ -n "$LOGFILE" ]; then
        date >> "$LOGFILE"
        agentinfo $HOST >> "$LOGFILE"
        ERR=$?
    else
        agentinfo $HOST
        ERR=$?
    fi
    return $ERR
}

function once_setup_host() {
    export NSH_RUNCMD_HOST="$1"

    export SHORT=`echo $NSH_RUNCMD_HOST | cut -f1 -d.`

    chkagent $NSH_RUNCMD_HOST
    ERR=$?
    if [ $ERR != 0 ]; then h_prefix echo chkagent $NSH_RUNCMD_HOST failed; return $ERR; fi
    
    cd //$NSH_RUNCMD_HOST
    ERR=$?
    if [ $ERR != 0 ]; then echo h_prefix cd //$NSH_RUNCMD_HOST failed; return $ERR; fi
}
function once_teardown_host() {
    HOST="$1"
    ## cd back to the server where the job is running from 
    cd //@
    disconnect
}

function prefix() {
    emulate -L sh
    # if emulate sh, use pipestatus[0]; if zsh, use pipestatus[1]
    # https://communities.bmc.com/thread/111527?start=0&tstart=0
    local prefix=$1
    shift
    { { "$@" | sed "s/^/$prefix /"; return ${pipestatus[0]}; } 3>&1 1>&2 2>&3 | sed "s/^/$prefix /"; return ${pipestatus[0]}; } 3>&1 1>&2 2>&3
}
function h_prefix() {
    if test -n "$SHORT"; then
        prefix $SHORT: $@
        return $?
    elif test -n "$short"; then
        prefix $short: $@
        return $?
    elif test -n "$SHORT_NSH_RUNCMD_HOST"; then
        prefix $SHORT_NSH_RUNCMD_HOST: $@
        return $?
    else
        prefix "NOHOSTVAR:" $@
        return $?
    fi
}
function two_empty_lines() {
    h_prefix echo
    h_prefix echo
}
function empty_line() {
    h_prefix echo
    h_prefix echo
}

function cleanup() {
    emulate sh
    local CODE="$1"
    local MESG="$2"

    if ! isint "$CODE"
    then
        h_prefix echo "so, CODE=$CODE is not an integer.  setting CODE=1"
        CODE=1
    fi
    h_prefix echo "$0: $MESG; cleaning up with exit code $CODE;"
    
#    blcli_disconnect 2> /dev/null
#    if ! test "$ERR" = 0; then h_prefix echo "blcli_disconnect:ERR=$?"; fi

    ## cd //@ goes back to the server where the job us running from.
    ## is this necessary on an --each script?
    cd //@ 2> /dev/null; 
    ERR=$?
    if ! test "$ERR" = 0; then h_prefix echo "cd //@:ERR=$?"; fi

    disconnect
    ERR=$?
    if ! test "$ERR" = 0; then h_prefix echo "disconnect:ERR=$?"; fi

    h_prefix echo "exiting CODE=$CODE"
    exit $CODE
}

function startup() {
    echo "in startup at `date`"
    local LANE="$1"
    local LOGDIR="$2"
    local LOG="$3" #filename

    echo $0: LANE=$LANE
    echo $0: LOGDIR=$LOGDIR
    echo $0: LOG=$LOG
    ## if we can mkdir //LOGHOST/LOGDIR, then set LOGBASE
    ## if LOG also defined, then LOGFILE=//LOGHOST/LOGDIR/LOG
    ## Then set TEE appropriately depending on if we have a valid log file     
    if ! setLogHost_PROD_OR_LLE "$LANE"
    then
        echo $0: LANE="$LANE is invalid - LOGHOST COULD NOT BE SET"
    elif test -n "$LOGDIR"
    then
        echo "doing mkdir \"//$LOGHOST$LOGDIR\""
        mkdir -p "//$LOGHOST$LOGDIR"
        export MKDIR_ERR=$?
        echo "mkdir status: $MKDIR_ERR"
        if test "$MKDIR_ERR" = 0; then
            export LOGBASE="//$LOGHOST$LOGDIR"
            echo "$0: LOGBASE=$LOGBASE"

            ## check for access to chkagent log
            ## if fail, clear it
            CHKAGENTLOG=$LOGBASE/chkagent.log
            touch "$CHKAGENTLOG"
            ERR=$?
            echo "touch $CHKAGENTLOG: ERR=$?"
            if [ $ERR = 0 ]; then
                export CHKAGENTLOG
                echo "CHKAGENTLOG=$CHKAGENTLOG"
            else
                CHKAGENTLOG=
            fi

            if test -n "$LOG"; then
                LOGFILE="$LOGBASE/$LOG"
                touch "$LOGFILE"
                ERR=$?
                if [ $ERR = 0 ]; then
                    echo LOGFILE=$LOGFILE
                else
                    LOGFILE="/dev/null"
                    echo LOGFILE="$LOGFILE"
                fi
                export LOGFILE
            fi
        else
            echo "$0: WARNING: mkdir $LOGBASE failed,"
            echo "$0: WARNING: so LOGBASE="
        fi
	
    fi

    if test -n "$NSH_RUNCMD_HOST"
    then
        chkagent $NSH_RUNCMD_HOST
        local AGENTERR=$?
        echo "$SHORT_NSH_RUNCMD_HOST: chkagent=$AGENTERR"
    fi
    empty_line
}
function isint() {
    local INT="$1"
    if echo $INT | egrep -q "^[0-9]+$"
    then return 0
    else return 1
    fi
}

function isLinux() {
    local KERNEL=`nexec $NSH_RUNCMD_HOST uname -s`
    if [ "$KERNEL" != "Linux" ]; then
        echo "$NSH_RUNCMD_HOST: Kernel is $KERNEL, not Linux."
        return 66
    else
        return 0
    fi        
}

function isAIX() {
    local KERNEL=`nexec $NSH_RUNCMD_HOST uname -s`
    if [ "$KERNEL" != "AIX" ]; then
        echo "$NSH_RUNCMD_HOST: Kernel is $KERNEL, not AIX."
        return 66
    else
        return 0
    fi        
}

function isHPUX() {
    local KERNEL=`nexec $NSH_RUNCMD_HOST uname -s`
    if [ "$KERNEL" != "HP-UX" ]; then
        echo "$NSH_RUNCMD_HOST: Kernel is $KERNEL, not HP-UX."
        return 66
    else
        return 0
    fi        
}

function assertLinux() {
    isLinux
    local ERR=$?
    if test "$ERR" != 0; then
        cleanup $ERR "OS is not Linux"
    fi
}

function assertAIX() {
    isAIX
    local ERR=$?
    if test $ERR != 0 ; then
        cleanup $ERR "OS is not AIX"
    fi
}

function assertHPUX() {
    isHPUX
    local ERR=$?
    if test $ERR != 0 ; then
        cleanup $ERR "OS is not HPUX"
    fi
}

function assertOS {
    ## takes a list of os types (linux,hpux/hp-ux,aix)
    ## and sees of this host is one of those
    local HOLDER="$@"
    local OS="$1"
    while test -n "$OS"
    do
        h_prefix echo "$0:checking if OS=$OS"
        local ERR=1
        if echo "$OS" | egrep -qi "^linux$"
        then
            isLinux
            ERR=$?
        elif echo "$OS" | egrep -qi "^(HPUX|HP-UX)$"
        then
            isHPUX
            ERR=$?
        elif echo "$OS" | egrep -qi "^AIX$"
        then
            isAIX
            ERR=$?
        fi
        if test "$ERR" = 0
        then
            h_prefix echo "is $OS"
            return 0
        else
            shift
            OS="$1"
        fi
     done
     cleanup 99 "$0: host is not in ($HOLDER)"
}
	
function strip() {
    local ARG="$1"
    ARG=`echo $ARG | sed -e 's/^\s+//' -e 's/\s+$//'`
    echo $ARG
}

function n_exec {
#   echo "starting nexec $NSH_RUNCMD_HOST $@"
    nexec $NSH_RUNCMD_HOST $@
}

function find_binary {
    # added may 10 2018 by mark price
    local H=$1;
    local BIN=$2
    shift
    shift
    for candidate in $@
    do
        if nexec $H test -x "$candidate"
        then
            echo $candidate
            return 0
        fi
    done
    candidate=$(nexec $H which $BIN)
    if test -n "$candidate"
    then
            echo $candidate
            return 0
    fi
    return 1
}

function source_header {
    local HEADERGRP="$1"
    local HEADERFILE="$2"
    local FILE=
    COUNT=0
    while test -z "$FILE"; do
        echo "looking up $HEADERFILE"
        FILE=`blcli_execute DepotObject getFullyResolvedPropertyValue DEPOT_FILE_OBJECT "$HEADERGRP" "$HEADERFILE" LOCATION\*`
        if test -z "$FILE";
        then
            COUNT=$((COUNT+1))
            sleep 5
        else
            echo "Found $HEADERFILE FILE=$FILE; `ls -l $FILE`"
        fi
        echo COUNT=$COUNT
        if test $COUNT = 5; then
            echo "couldnt find $FILE.  Exiting"
            exit 99
        fi
    done
    source $FILE
    h_prefix echo "$FILE sourced"
}
