#!/usr/bin/env /bin/bash

#command line parameters: "number of packets to send", "scan interval"
# then loop doing a scan each pass while the packets are being sent... 
#     whether using ping or directly injecting packets, I dont care...
# the output from the scan is appended to the logfile with a timestamp1

# source shflags
. ./lib/shflags

# DEFINE_string 'dev' 'wlan0' 'device to read RSSI values from' 'd' 



######### UserInterface ############
####################################
# configure shflags
DEFINE_integer 'count' 100 'number of RSSI values to record' 'c'
DEFINE_integer 'seconds' 0 'number of seconds to record' 's'
DEFINE_integer 'msecs' 0 'number of milliseconds to record' 'm'
DEFINE_integer 'interval' 500 'frequency in milliseconds to record RSSI values' 'i'
DEFINE_string 'timestamp' 'zero' 'logged timestamp format: (zero | now | none )' 't'
DEFINE_boolean 'quiet' true 'suppress message output to stdout' 'q'
DEFINE_boolean 'overwrite' true 'overwrite old log files' 'o'
DEFINE_boolean 'headers' true 'prepend logfile with column headers' 'H'
DEFINE_boolean 'transmit' false 'transmit packets to the access point' 'x'
DEFINE_integer 'packetsize' 8 'size of the packet to transmit +8 bytes for header' 'p'
DEFINE_string 'file' 'rrs_log.csv' 'file to save the RSSI log results' 'f'


# assigns input from the cli to the corresponding flag variable
setFlags()
{
	# parse the command-line
	FLAGS "$@" || exit $?
	eval set -- "${FLAGS_ARGV}"

	# sets the delay between readings to seconds (with fractions)
	RSSI_READ_INTERVAL=$(echo "scale=4; $FLAGS_interval/1000" | bc -l)"s"

	# sets the proper timestamp to prepend to each reading
	[[ $FLAGS_timestamp -eq "zero" ]] && START_TIME=$(date +%s%3N) || START_TIME=0
	DELTA=3 # small offset to adjust for START_TIME recording to first timestamp

	# toggles whether to print output to the screen as well as the log file
	[[ $FLAGS_quiet -eq $FLAGS_TRUE ]] && setDisplayPath "/dev/null" ||	setDisplayPath "/dev/fd/3"
}

# set the (nonpersistant) display path
setDisplayPath()
{
	displayPath=$1
}

# return the path being used for the display
getDisplayPath()
{
	echo "$displayPath"
}

# verify the user input is valid or exits
validateInput()
{
	[[ $1 -ne $2 ]] && echo "Invalid input format." >&2;
	exit 1;
}

# print the commandline options to the screen
printOptions()
{
	if [[ -e /dev/fd/3 ]]; then
		rrs.sh -h >&1;
	else
		rrs.sh -h | tee /dev/fd/3
	fi
}

# display pretty print error messages
printErrors()
{
	local errMsg
	[[ -z "$1" ]] && errMsg="An error has occurred. RRS is terminating." || errMsg="$1"
	if [[ -e /dev/fd/3 ]]; then
		echo "$errMsg" | tee /dev/fd/3;
		exit 1;
	else
		echo "$errMsg";
		exit 1;
	fi
}

########### PacketTransmitter #############
###########################################
# Sends packets to the access point
sendPacket()
{
	ping -4nq -c $packetCount -i $transmitInterval -I getDevName -s packetsize getAPIP &
	pingPID=$!
}

# Cancels the active packet transmission
cancelTransmission()
{
	kill -SIGTERM $pingPID;
}

# Returns the name of the wireless network adapter (grabs the first in case of
#  multiple adapters.)
getDevName()
{
	echo "iw dev | awk '/Interface/ { print $2 }'"
}

# Gets the access point's IP address
getAPIP()
{
	local var=$(getDevName)
	echo $(ip route show | grep $var | awk 'NR==1 { print $3 }')
}

# Init function for the PacketTransmitter 'class'
packetTransmitter()
{
	packetCount=$FLAGS_count
	transmitInterval=$FLAGS_interval
	packetsize=$FLAGS_packetsize
	destination=getAPIP
}
########### RSSIParser #############
####################################
# This parser is specific to Raspbian 9 (stretch), the value reported for quality
#		level is determined by the wireless nic's driver. If you want any other
#		values reported in /proc/net/wireless just add their respective capture
#		class ($3 should be quality link and $5 quality noise).
parseRSSIValue()
{
	if [[ $1 -eq true ]]; then
		awk -F ".[ ]+" -v date="$(($(date +%s%3N)-START_TIME-DELTA))" 'NR==3 {print date "," $4}'	/proc/net/wireless | tee $display_path
	else
		awk -F ".[ ]+" 'NR==3 {print $4}' /proc/net/wireless | tee getDisplayPath
	fi
}

# Calculates the time offset from user input
calculateEndSeconds()
{
	END_SECONDS=$(echo "scale=4; $FLAGS_msecs/1000 + $FLAGS_seconds" | bc -1)
}

# Calculates the future time to stop reading RSSI values
calculateStopTime()
{
	STOP_TIME=$(date +%s%3N -d "+$END_SECONDS")
}

##
#  Read the RSSI value for a set number of times
#
readRSSIByCounter()
{
	if [ ${FLAGS_timestamp} != "none" ]; then
		for i in `seq 1 ${FLAGS_count}`;
		do
			parseRSSIValue true
			DELTA=0
			sleep $RSSI_READ_INTERVAL
		done
	else
		for i in `seq 1 ${FLAGS_count}`;
		do
			parseRSSIValue false
			sleep $RSSI_READ_INTERVAL
		done
	fi
}

##
#	 This parser repeats until the current date is greater than or equal to the stop time.
#
readRSSIByTimer()
{
	calculateEndSeconds
	calculateStopTime	
	if [ ${FLAGS_timestamp} != "none" ]; then
		for i in `seq 1 ${FLAGS_count}`; # while (date -lt STOP_TIME);
		do
			awk -F ".[ ]+" -v date="$(($(date +%s%3N)-START_TIME))" 'NR==3 {print date "," $4}'	/proc/net/wireless | writeToFile getDisplayPath
			sleep $RSSI_READ_INTERVAL
		done
	else
		for i in `seq 1 ${FLAGS_count}`; # while (date -lt STOP_TIME);
		do
			awk -F ".[ ]+" 'NR==3 {print $4}' /proc/net/wireless | writeToDisplay getDisplayPath
			sleep $RSSI_READ_INTERVAL
		done
	fi
}


########### RSSILogger #############
####################################
# Clear the contents of the target log file
overwriteFile()
{
	rm $FLAGS_file
	touch $FLAGS_file
}

# Verify the output file exists
verifyOutput()
{
	[[ -e "$FLAGS_file" ]] && echo true
}

# compute a timestamp for logging
calculateTimeStamp()
{
	timeStamp="$(($(date +%s%3N)-START_TIME))"
}

# get the last computed timestamp value
getTimeStamp()
{
	echo "$timeStamp"
}

# redirect the value passed to this function to the display
writeToDisplay()
{
	[[ true -eq $((0)) ]] && tee $1
}

# redirect the value passed to this function to the file
writeToFile()
{
	[[ $((0)) -eq true ]] && tee $1
}

##
# Handles creating & preparing new log files if needed. Also tests for write access.
##
initLogFile()
{
	if [ -w "$FLAGS_file" ]; then
		if [ $FLAGS_overwrite -eq $FLAGS_TRUE ]; then
			overwriteFile
		fi
	elif [ -e "$FLAGS_file" ]; then
		printErrors "Error! Cannot overwrite the logfile $FLAGS_file."
		exit 1;
	else
		touch $FLAGS_file
	fi

	# set all 1 & 2 output to append to the file while leaving fd 3 attached to stdout
  exec 3>&1 1>>${FLAGS_file}
  [[ $FLAGS_headers -eq $FLAGS_TRUE ]] && echo "time,RSSI"
}


########
# Main #
########
setFlags
initLogFile
[[ $FLAGS_transmit -eq true ]] && packetTransmitter && sendPacket
# Counter or Timer?
if [ $((FLAGS_seconds + FLAGS_msecs)) -gt 0 ]; then
	readRSSIByTimer
else
	readRSSIByCounter
fi

###### old commands I might need ######
#sudo iwlist wlxec1a595e181d scan | grep 'Signal level=' | awk -F'[=]' '{print $3}' | head -n1
#watch -n 1 "awk 'NR==3 {print \"WiFi Signal Strength = \" \$3 \"00 %\"}''' /proc/net/wireless"