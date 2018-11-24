#!/usr/bin/env /bin/bash

#command line parameters: "number of packets to send", "scan interval"
# then loop doing a scan each pass while the packets are being sent... 
#     whether using ping or directly injecting packets, I dont care...
# the output from the scan is appended to the logfile with a timestamp1
LOG_FILE="rrs.log"
RSSI_READ_INTERVAL=.2
RSSI_READ_COUNT=10
LOGGED_START_TIME="zero" # other option would be "now"
START_TIME=$(date +%s%3N)

# This parses specific to Raspbian 9 (stretch), the value reported for quality
#		level is determined by the wireless nic's driver. If you want any other
#		values reported in /proc/net/wireless just add their respective capture
#		class ($3 should be quality link and $5 quality noise).
capture_rssi()
{
  exec 3>&1 1>>${LOG_FILE}
  echo "time,RSSI"
  for i in `seq 1 $RSSI_READ_COUNT`;
  do
    awk -F ".[ ]+" -v date="$(($(date +%s%3N)-START_TIME))" 'NR==3 {print date "," $4}' /proc/net/wireless
    sleep $RSSI_READ_INTERVAL
  done
}

write_log()
{
	while read text
	do
		LOGTIME=$(date +%s)
		# check if logfile exists
		if [ "$LOG_FILE" == "" ]; then
			echo $LOGTIME": $text";
		else
			LOG=$LOG_FILE.$(date +%Y%m%d)
			touch $LOG
			if [ ! -f $LOG ]; then echo "Error! Cannot create the logfile $LOG."
				exit 1; fi
			echo $LOGTIME": $text" | tee -a $LOG;
		fi
	done
}

######
# Main
######
capture_rssi

###### old commands I might need ######
#sudo iwlist wlxec1a595e181d scan | grep 'Signal level=' | awk -F'[=]' '{print $3}' | head -n1

#watch -n 1 "awk 'NR==3 {print \"WiFi Signal Strength = \" \$3 \"00 %\"}''' /proc/net/wireless"