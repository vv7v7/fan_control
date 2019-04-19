#!/bin/sh
 
#########################################################################################################################
# License

# A service script for "fan.sh"
# Copyright 2019 by V7
# Licensed under GNU General Public License 3.0. 
# Some rights reserved. See LICENSE.
# @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>

### BEGIN INIT INFO
# Provides:          fan
# Required-Start:    
# Required-Stop:     
# X-Start-Before:    kdm gdm3 xdm lightdm
# X-Stop-After:      kdm gdm3 xdm lightdm
# Default-Start:     2 3 4 5
# Default-Stop:      
# Short-Description: Fan service
# Description:       Provides a customizable and automatic fan control system(initially, for Lenovo laptop(ThinkPad))
### END INIT INFO

set -e

fan_script_path="/opt/fan/fan.sh" # Script location

# Check if script exists
[ -x "$fan_script_path" ] || exit 0

# Get lsb functions
. "/lib/lsb/init-functions"

set +e

fan_service_status_fn_1_v=""
fan_service_status_fn() {
	fan_service_status_fn_1_v=$(ps aux | grep -i "$fan_script_path" | grep "bash" | grep -v "grep")
	if [ "${#fan_service_status_fn_1_v}" != "0" ]; then
		return 0
	fi
	return 1
}

case "$1" in
	"start")
		if ! fan_service_status_fn; then
			/bin/bash "$fan_script_path" &
			sleep 1
			if fan_service_status_fn; then
				log_daemon_msg "Fan service successfully started"
				exit 0
			fi
			log_daemon_msg "Fan service failed to start"
			exit 1
		else
			log_daemon_msg "Fan service is already running"
			exit 1
		fi
	;;
	"stop")
		if fan_service_status_fn; then
			ps aux | grep -i "$fan_script_path" | grep "bash" | grep -v "grep" | awk '{print $2}' | while read fan_service_1_v; do
				log_daemon_msg "Killing \"""$fan_service_1_v""\""
				kill -s 1 "$fan_service_1_v" > /dev/null 2>&1
			done
			sleep 1
			if ! fan_service_status_fn; then
				log_daemon_msg "Fan service successfully stopped"
			else
				log_daemon_msg "Fan service might failed to stop"
			fi
			log_end_msg "$?"
			exit 0
		else
			log_daemon_msg "Fan is already not running"
			exit 1
		fi
	;;
	"restart")
		"$0" stop
		sleep 1
		"$0" start
	;;
	"status")
		status_of_proc "$fan_script_path" "fan"
	;;
	*)
		log_success_msg "Usage: /etc/init.d/fan {start|stop|restart|status}"
		exit 1
	;;
esac
