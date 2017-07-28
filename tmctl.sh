#!/bin/bash
# Description: Controls the tmate-master auto init, and keep the slave aware of changes on the connection string.
#
# Setup:
# 1 - Save this script on /sbin/tmctl.sh;
# 2 - Grant execution privileges;
# 3 - Add to start-up: echo "/sbin/tmctl.sh start" >> /etc/rc.local
# 4 - Config notify funcion: echo "*/15 * * * * root /sbin/tmctl.sh notify" >> /etc/crontab
# 5 - Config monitor funcion: echo "*/15 * * * * root /sbin/tmctl.sh monitor" >> /etc/crontab
#


#
# Var definitions
#

TMATE=`which tmate`
SSH=`which ssh`
TMTMSTR=`hostname`
TMTSLV="<SOME-IP-ADDR>"

#
#Functions
#


START(){
	echo "Starting tmate as detached session..." 2>&1 >> /var/log/tmatemaster.log
	$TMATE -S /tmp/tmate.sock new-session -d               # Launch tmate in a detached state
	$TMATE -S /tmp/tmate.sock wait tmate-ready             # Blocks until the SSH connection is established 
	NOTIFY
}

STOP(){
	echo "Stoping tmate (killing processes)..." 2>&1 /var/log/tmatemaster.log 
	ps -ef | grep tmate | awk '{print $2}' | xargs kill -9
}

PROCMON(){
	STATUS=`ps -ef | grep tmate | grep -v grep | wc -l`
	# STATUS = 0 means that has no processes running:
	if [ "$STATUS" == 0 ]; then
		echo "tmate is stopped, starting that..." 2>&1 >> /var/log/tmatemaster.log
		START
	fi
}

NOTIFY(){
	# Feed $CONNSTR with the SSH connection string value
	CONNSTR=`$TMATE -S /tmp/tmate.sock display -p '#{tmate_ssh}'| awk '{print $3}'`
	if [ "$TMATECONSTR" != "$CONNSTR" ]; then
		echo "`date` - The Connection String has been changed! New Address: $CONNSTR" | $SSH root@$TMTSLV "cat >> /var/log/tmate-control.log"
		export TMATECONSTR="$CONNSTR"
		#exit 1
	else
		echo "`date` - The Connection String stay the same." | $SSH root@$TMTSLV "cat >> /var/log/tmate-control.log"
		#exit 0
	fi
}


#
# Script options
#
case $1 in
	start)
		START
		;;

	stop)
		STOP
		;;

	restart)
		STOP
		START
		;;

	monitor)
		PROCMON
		;;

	notify)
		NOTIFY
		;;
			
	*)
		echo -e "Try $0 {start|stop|monitor|notify|restart}"
		;;
		    
esac

