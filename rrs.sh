#!/usr/bin/env /bin/bash

#command line parameters: "number of packets to send", "scan interval"
# then loop doing a scan each pass while the packets are being sent... 
#     whether using ping or directly injecting packets, I dont care...
# the output from the scan is appended to the logfile with a timestamp1

# source shflags
. ./lib/shflags

# configure shflags
# DEFINE_string 'dev' 'wlan0' 'device to read RSSI values from' 'd' 
DEFINE_integer 'count' '100' 'number of RSSI values to record' 'c'
DEFINE_integer 'seconds' '300' 'number of seconds to record' 's'
DEFINE_integer 'msecs' '30000' 'number of milliseconds to record' 'm'
DEFINE_integer 'interval' 500 'frequency in milliseconds to record RSSI values' 'i'
DEFINE_string 'timestamp' 'zero' 'logged timestamp format: (zero | now | none )' 't'
DEFINE_boolean 'quiet' true 'suppress message output to stdout' 'q'
DEFINE_boolean 'overwrite' true 'overwrite old log files' 'o'
DEFINE_boolean 'headers' true 'prepend logfile with column headers' 'H'
DEFINE_boolean 'transmit' false 'transmit packets to the access point' 'x'
DEFINE_integer 'packetsize' 8 'size of the packet to transmit +8 bytes for header' 'p'
DEFINE_string 'file' 'rrs_log.csv' 'file to save the RSSI log results' 'f'

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# sets the delay between readings to seconds (with fractions)
RSSI_READ_INTERVAL=$(echo "scale=4; $FLAGS_interval/1000" | bc -l)

# sets the proper timestamp to prepend to each reading
[[ $FLAGS_timestamp == "zero" ]] && START_TIME=$(date +%s%3N) || START_TIME=0

# toggles whether to print output to the screen as well as the log file
if [ $FLAGS_quiet -eq $FLAGS_TRUE ]; then 
	display_path="/dev/null"; 
else 
	display_path="/dev/fd/3";
fi

# This parser is specific to Raspbian 9 (stretch), the value reported for quality
#		level is determined by the wireless nic's driver. If you want any other
#		values reported in /proc/net/wireless just add their respective capture
#		class ($3 should be quality link and $5 quality noise).
capture_rssi_by_counter()
{
	if [ ${FLAGS_timestamp} != "none" ]; then
		for i in `seq 1 ${FLAGS_count}`;
		do
			awk -F ".[ ]+" -v date="$(($(date +%s%3N)-START_TIME))" 'NR==3 {print date "," $4}'	/proc/net/wireless | tee $display_path
			sleep $RSSI_READ_INTERVAL
		done
	else
		for i in `seq 1 ${FLAGS_count}`;
		do
			awk -F ".[ ]+" 'NR==3 {print $4}' /proc/net/wireless | tee $display_path
			sleep $RSSI_READ_INTERVAL
		done
	fi
}


capture_rssi_on_timer()
{
	if [ ${FLAGS_timestamp} != "none" ]; then
		for i in `seq 1 ${FLAGS_count}`;
		do
			awk -F ".[ ]+" -v date="$(($(date +%s%3N)-START_TIME))" 'NR==3 {print date "," $4}'	/proc/net/wireless | tee $display_path
			sleep $RSSI_READ_INTERVAL
		done
	else
		for i in `seq 1 ${FLAGS_count}`;
		do
			awk -F ".[ ]+" 'NR==3 {print $4}' /proc/net/wireless | tee $display_path
			sleep $RSSI_READ_INTERVAL
		done
	fi
}


##
# Handles creating & preparing new log files if needed. Also tests for write access.
##
init_log_file()
{
	if [ -w "$FLAGS_file" ]; then
		if [ $FLAGS_overwrite -eq $FLAGS_TRUE ]; then
			rm $FLAGS_file
			touch $FLAGS_file
		fi
	elif [ -e "$FLAGS_file" ]; then
		echo "Error! Cannot overwrite the logfile $FLAGS_file."
		exit 1;
	else
		touch $FLAGS_file
	fi

  exec 3>&1 1>>${FLAGS_file}
  [[ $FLAGS_headers -eq $FLAGS_TRUE ]] && echo "time,RSSI"
}

########
# Main #
########
init_log_file

# Counter or Timer?
capture_rssi_by_counter
#capture_rssi_on_timer


###### old commands I might need ######
#sudo iwlist wlxec1a595e181d scan | grep 'Signal level=' | awk -F'[=]' '{print $3}' | head -n1

#watch -n 1 "awk 'NR==3 {print \"WiFi Signal Strength = \" \$3 \"00 %\"}''' /proc/net/wireless"