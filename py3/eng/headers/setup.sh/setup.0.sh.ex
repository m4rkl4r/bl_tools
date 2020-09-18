# created by mark price, starting Feb 2018

SHORT_NSH_RUNCMD_HOST=`echo $NSH_RUNCMD_HOST | cut -f1 -d.`

function found_setup() {
    true
}

function chkagent {
    local  HOST=$1
    local LOGFILE="$2"

    ERR=
    if [ -n "$LOGFILE" ]; then
        echo "chkagent() is using LOGFILE=$LOGFILE"
        date >> "$LOGFILE"
        agentinfo $HOST >> "$LOGFILE"
        ERR=$?
    else
        agentinfo $HOST
        ERR=$?
    fi
    return $ERR
}

function prefix() {
    #emulate zsh
    # https://communities.bmc.com/thread/111527?start=0&tstart=0
    local prefix=$1
    shift
    { { "$@" | sed "s/^/$prefix /"; return ${pipestatus[1]}; } 3>&1 1>&2 2>&3 | sed "s/^/$prefix /"; return ${pipestatus[1]}; } 3>&1 1>&2 2>&3
}
function h_prefix() {
    if test -n "$SHORT"; then
        prefix $SHORT: $@
    elif test -n "$short"; then
        prefix $short: $@
    elif test -n "$SHORT_NSH_RUNCMD_HOST"; then
        prefix $SHORT_NSH_RUNCMD_HOST: $@
    else
        prefix "NOHOSTVAR:" $@
    fi
}

function cleanup() {
    emulate sh
    local CODE="$1"
    local MESG="$2"

    h_prefix echo "$0: `date`: Exit $CODE; $MESG"
    
    blcli_disconnect 2> /dev/null
    cd //@ 2> /dev/null; disconnect 2> /dev/null
    if isint $CODE; then
        exit $CODE
    else:
        h_prefix "so, $CODE is not an integer.  Exiting anyways"
        exit 1
    fi
}

function startup() {
    echo "in startup at `date`"
    local LOGHOST="$1"
    local LOGDIR="$2"
    local LOG="$3" #filename
    local CHKAGENTLOG=

	echo startup: LOGHOST=$LOGHOST
	echo startup: LOGDIR=$LOGDIR
	echo startup: LOG=$LOG
	## if we can mkdir //LOGHOST/LOGDIR, then set LOGBASE
	## if LOG also defined, then LOGFILE=//LOGHOST/LOGDIR/LOG
	## Then set TEE appropriately depending on if we have a valid log file     
    if test -n "$LOGHOST" && test -n "$LOGDIR"
    then
    	echo "doing mkdir \"//$LOGHOST$LOGDIR\""
    	mkdir -p "//$LOGHOST$LOGDIR"
    	export MKDIR_ERR=$?
    	echo "mkdir status: $MKDIR_ERR"
    	if test "$MKDIR_ERR" = 0; then
    		export LOGBASE="//$LOGHOST$LOGDIR"
    		echo LOGBASE="$LOGBASE"
    		if test -n "$LOG"; then
    			LOGFILE="$LOGBASE/$LOG"
    			export LOGFILE="$(echo $LOGFILE | sed -e 's/ /\\ /g')"
    			echo LOGFILE="$LOGFILE"
    			touch "$LOGFILE"
    			echo "touch $LOGFILE: ERR=$?"
    		fi
    	fi
    fi
    if test -n "$LOGFILE"; then
    	export TEE="tee -a $LOGFILE"
    else
    	export TEE="tee /dev/null"
	fi
	echo TEE=$TEE
 
	if test -n "$NSH_RUNCMD_HOST"
	then
	    chkagent $NSH_RUNCMD_HOST //$LOGHOST$LOGDIR/chkagent.`date -I`
    	local AGENTERR=$?
    	echo "$SHORT_NSH_RUNCMD_HOST: chkagent=$AGENTERR"
	fi
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
        echo "$NSH_RUNCMD_HOST: Assert Kernel is $KERNEL, not Linux."
        return 66
    else
        return 0
    fi        
}
function assertLinux() {
    if ! isLinux; then
        local ERR=$?
        echo "exit $ERR"
        exit $ERR
    fi
}

function strip() {
    local ARG="$1"
    ARG=`echo $ARG | sed -e 's/^\s+//' -e 's/\s+$//'`
    echo $ARG
}

function n_exec {
	echo n_exec: NSH_RUNCMD_HOST=$NSH_RUNCMD_HOST
	echo n_exec: '$@'=$@
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
