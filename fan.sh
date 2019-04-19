#!/bin/bash

#########################################################################################################################
# License

# A customizable script to control fan
# Copyright 2019 by V7
# Licensed under GNU General Public License 3.0. 
# Some rights reserved. See LICENSE.
# @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>

#########################################################################################################################
# About

# Script: A script to control fan(initially, for Lenovo laptop(ThinkPad))
# Author: V7
# Version: v1.0 142745_07042019
# Description: Provides a customizable and automatic control of fan
# Information: In case of Lenovo laptop(ThinkPad), to make this script work make sure there's "/proc/acpi/ibm/fan"
# driver and "fan_control" is enabled(i.e. "options thinkpad_acpi fan_control=1" exists in
# "/etc/modprobe.d/thinkpad_acpi.conf" file(don't forget to reboot after changing this file))
# Usage: "/bin/bash fan.sh", "./fan.sh"

#########################################################################################################################
# Configuration

fan_1_config=( # Temperature thresholds(Tempature Level). Please, check "cat /proc/acpi/ibm/fan" which options supports your driver.
	90 disengaged
	85 7
	80 6
	75 5
	70 4
	65 3
	60 2
	55 1
	50 0
)
fan_2_config="1" # Timeout in seconds between checking temperature(supports float and suffix). Please, check "man sleep".
fan_3_config="/proc/acpi/ibm/fan" # Fan driver.
fan_4_config="2000" # Timeout of fan switch in miliseconds.
fan_5_config="1" # When not found a threshold: "0" ~ switch to "0" level, "1" ~ switch to minimum threshold and "2" ~ switch to "auto" level.
fan_6_config="0" # Override timeout of fan switch: "0" ~ disable, "1" ~ enable.
fan_7_config="0" # On exit switch: "0" ~ switch to "auto", "1" ~ switch to initial and "2" ~ do not switch(just exit).
fan_8_config="0" # Verbose level: "0" ~ no output, "1" ~ only errors, "2" ~ only switches and "3" ~ all output.

#########################################################################################################################
# Variables

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
fan_1_v="" # Core 0 temperature
fan_2_v="" # Core 2 temperature
fan_3_v="" # ACPI temperature
fan_4_v="" # Fan speed
fan_5_v="" # Fan level
fan_6_v="" # Max temperature
fan_7_v="" # Time of switch
fan_8_v="" # Initial fan level

#########################################################################################################################
# Functions

function fan_time_ms {
	date '+%s%3N'
}

function fan_output_fn {
	if [ "$TERM" != "" ] && [ "$TERM" != "dumb" ]; then
		if ( (( "$#" > "1" )) && [[ "$fan_1_v" =~ [0-9]+$ ]] ) || [ "$*" = "1" ]; then
			if [ "$*" != "1" ]; then
				if (( "$fan_8_config" >= "$1" )); then
					shift
					echo "$@"
				fi
			else
				clear
			fi
		else
			echo "[ - ] Wrong arguemnts for \"fan_output_fn\" function"
		fi
	fi
}

function fan_update_fn {
	fan_update_fn_1_v="$(sensors)"
	fan_1_v="$(echo "$fan_update_fn_1_v" | grep 'Core 0' | awk '{print $3}' | sed 's/+//g' | sed 's/\..*//g')"
	fan_2_v="$(echo "$fan_update_fn_1_v" | grep 'Core 2' | awk '{print $3}' | sed 's/+//g' | sed 's/\..*//g')"
	fan_3_v="$(echo "$fan_update_fn_1_v" | tail +10 | grep 'temp1' | awk '{print $2}' | sed 's/+//g' | sed 's/\..*//g')"
	fan_4_v="$(echo "$fan_update_fn_1_v" | grep 'fan1' | awk '{print $2}')"
	fan_5_v="$(cat '/proc/acpi/ibm/fan' | grep -i 'level:' | awk '{print $2}')"
	if [[ "$fan_1_v" =~ [0-9]+$ ]] && [[ "$fan_2_v" =~ [0-9]+$ ]] && [[ "$fan_3_v" =~ [0-9]+$ ]] && [[ "$fan_4_v" =~ [0-9]+$ ]]; then
		fan_6_v="$fan_1_v"
		if (( "$fan_2_v" > "$fan_6_v" )); then fan_6_v="$fan_2_v"; fi
		if (( "$fan_3_v" > "$fan_6_v" )); then fan_6_v="$fan_3_v"; fi
		return 0
	fi
	fan_6_v=""
	return 1
}

function fan_threshold_fn {
	for (( fan_check_fn_1_v = 0; fan_check_fn_1_v < "${#fan_1_config[@]}"; fan_check_fn_1_v += 2 )); do
		local fan_check_fn_2_v="${fan_1_config[$fan_check_fn_1_v]}"
		local fan_check_fn_3_v="${fan_1_config[$(($fan_check_fn_1_v + 1))]}"
		if (( "$fan_6_v" >= "$fan_check_fn_2_v" )); then
			echo "$fan_check_fn_3_v"
			return 0
		fi
	done
	echo "$fan_check_fn_3_v"
	return 1
}

function fan_switch_fn {
	fan_output_fn 3 "[ * ] Fan switch request from \"$fan_5_v\" to \"""$1""\""
	if [ "$#" = "1" ] && ( [[ "$1" =~ [0-9]+$ ]] || [ "$1" = "auto" ] || [ "disengaged" ] || [ "$1" = "full-speed" ] ); then
		if [ "$fan_5_v" != "$1" ]; then
			fan_switch_fn_1_v="$(( $(fan_time_ms) - $fan_7_v ))"
			if [ "$fan_6_config" = "1" ] || (( "$fan_switch_fn_1_v" >= "$fan_4_config" )); then
				fan_output_fn 2 -n "[ * ] Switching from \"$fan_5_v\" to \"""$1""\" at temperature \"$fan_6_v\": "
				if { echo "level" "$1" > "$fan_3_config"; } > /dev/null 2>&1; then
					fan_7_v="$(fan_time_ms)"
					fan_5_v="$1"
					fan_output_fn 2 "success"
					return 0
				else
					fan_output_fn 2 "fail"
				fi
			else
				fan_output_fn 3 "[ ! ] Too fast switch. Waiting \"$fan_switch_fn_1_v""ms""\" of \"$fan_4_config""ms""\"."
			fi
		else
			fan_output_fn 3 "[ * ] Fan is already on \"""$1""\" level"
		fi
	else
		fan_output_fn 1 "[ - ] Incorrect level provided: \"$1\""
	fi
	return 1
}

function fan_check_fn {
	local fan_check_fn_1_v; fan_check_fn_1_v="$(fan_threshold_fn)"
	fan_check_fn_2_v="$?"
	if [ "$fan_check_fn_2_v" = "0" ]; then
		fan_output_fn 3 "[ + ] Threshold found for temperature \"$fan_6_v\""
		fan_switch_fn "$fan_check_fn_1_v"
	else
		fan_output_fn 3 "[ ! ] Threshold not found for temperature \"$fan_6_v\""
		case "$fan_5_config" in
			"0") fan_switch_fn "0";;
			"1") fan_switch_fn "$fan_check_fn_1_v";;
			"2") fan_switch_fn "auto";;
				*) fan_switch_fn "auto";;
		esac
	fi
}

function fan_exit_fn {
	fan_output_fn 3 ""
	fan_output_fn 3 "[ ! ] Exiting"
	case "$fan_7_config" in
		"1")
			fan_6_config="1"
			fan_output_fn 3 "[ * ] Switching fan to initial \"$fan_8_v\" level"
			fan_switch_fn "$fan_8_v"
		;;
		"2")
			fan_output_fn 3 "[ ! ] Force"
		;;
		*)
			fan_6_config="1"
			fan_output_fn 3 "[ * ] Switching fan to \"auto\" level"
			fan_switch_fn "auto"
		;;
	esac
	exit 0
}

#########################################################################################################################
# Preinitialization

fan_output_fn "1"
fan_7_v="$(fan_time_ms)"

#########################################################################################################################
# Check preinitialization

if [[ "$fan_7_v" =~ [0-9]+$ ]]; then
	if (( "$fan_7_v" > "$fan_4_config" )); then
		fan_7_v=$(($fan_7_v - $fan_4_config))
	fi
else
	fan_output_fn 1 "[ - ] Failed to initialize time"
	exit 1
fi

#########################################################################################################################
# Postinitialization

if fan_update_fn; then
	fan_8_v="$fan_5_v"
fi

#########################################################################################################################
# Check postinitialization

if [ "$fan_8_v" != "" ]; then
	trap fan_exit_fn SIGINT SIGHUP
else
	fan_output_fn 1 "[ - ] Failed to initialize variables"
	exit 2
fi

#########################################################################################################################
# Main

while true; do
	if fan_update_fn; then
		fan_check_fn
	fi
	sleep "$fan_2_config"
done
