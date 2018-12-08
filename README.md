# rrs
RSSI Recording Software (script) - records RSSI values to a log file

rrs(1)                      General Commands Manual                     rrs(1)

NAME
       rrs - RSSI Reader Software

SYNOPSIS
       rrs -h
       rrs --help
       rrs -V
       rrs --version
       rrs [-c count ] [-s seconds ] [-m milliseconds ] [-i milliseconds ] [-t
       option ] [--noquiet]  [--nooverwrite]  [--noheaders]  [-d  delimiter  ]
       [--notransmit] [-p size ] [-f file ]

DESCRIPTION
       rrs  is a (fairly) highspeed IPv4 utility that reads a wireless network
       card's connection strength values. The Radio Signal Strength Indication
       values  are  read up to 10 times per second and saved to an output file
       (and optionally displayed to the console).  rrs requires an established
       wireless  network connection. The RSSI value is updated by the wireless
       nic when a packet is recieved from the wireless access point or router.
       To  ensure  consistent  RSSI  updates  rrs  [optionally] transmits ICMP
       ECHO_REQUEST datagrams via the ping utility.

       Note that while this utility should work on other versions of linux, it
       has only been tested on Raspian 9 (Stretch) on a Raspberry Pi 3 B+ with
       the onboard wireless nic and  Ubuntu  18.04  (Bionic  Beaver)  using  a
       Belkin  USB wireless nic.  Each device manufacturer's implementation of
       RSSI reporting may vary, therefore the format and meaning  of  recorded
       values  should be treated as inconsistent across devies.  rrs polls the
       procfs file /proc/net/wireless for RSSI  data.  The  implementation  of
       procfs can vary between distros, which may render rrs incompatible with
       certain linux flavors.

EXAMPLES
       rrs -h
              Print all commandline options and their default  values  to  the
              console.
       rrs
              Run rrs with defaul values to produce a logfile of RSSI values.
       rrs -i 100 -c 10000 --noquiet | sudo feedgnuplot --stream .1 --xlen 100
           --ymin -90 --ymax -10 --lines --xlabel 'Time' --ylabel 'RSSI'
              This example  must  be  run  in  an  X-Windows  environment  and
              requires   feedgnuplot  (https://github.com/dkogan/feedgnuplot).
              The ymin and ymax values here are for Raspberry Pi 3 B+,  adjust
              to  your  readings  as  necessary.  The  resulting  output  is a
              scrolling line graph of real-time RSSI value changes.

FILES
       ./lib/
              Support files needed for rrs to work.

OPTIONS
       -c, --count count
              Record by count. Specifies the number of RSSI readings to  take.
              This  option  takes precedence over --seconds or --milliseconds.
              If --count is specified, record by time options are ignored.

       -s, --seconds seconds
              Record by time. Specifies how many seconds to record RSSI  read‐
              ings  for.  This option combines with --milliseconds additively.
              If --count is specified, record by time options are ignored.

       -m, --milliseconds milliseconds
              Record by time. Specifies how many milliseconds to  record  RSSI
              readings for. This option combines with --seconds additively. If
              --count is specified, record by time options  are  ignored.  The
              fastest RSSI values can be read is 100 ms.  Any value lower than
              that is treated as 100 ms.

       -i, --interval milliseconds
              Specifies the frequency of RSSI readings to take given  in  mil‐
              liseconds.  The  fastest  RSSI values can be read is 100 ms. Any
              value lower than that is treated as 100 ms.

       -t, --timestamp OPTION
              Specifies the format of the timestamp that  prepends  each  RSSI
              reading.   Timestamps  increment roughly equal to the --interval
              and is measured in milliseconds.
                  zero - Uses a timer starting at 0.
                  now  - Prints the local time for each reading.
                  none - No timestamp is added.

       -q, --[no]quiet
              Suppress readings output to stdout. To  have  the  reading  dis‐
              played  to  the  console  as well as written to the log file use
              either --noquiet or --quiet false.

       -o, --[no]overwrite
              Overwrite existing log file if it has  the  same  file  name  as
              specified  (or  default). If disabled log files will be appended
              to. To disable use --nooverwrite or --overwrite false.

       -H, --[no]headers
              Write column headers as the first line written to the log  file.
              To disable writing headers use --noheaders or --headers false.

       -d, --delimiter String
              Defines  the  column  separator for each RSSI reading output. If
              the delimiter includes whitespace it must be surrounded by  dou‐
              ble quotes.

       -x, --[no]transmit
              Transmit  ICMP  packets  to  the  access  point.  To disable use
              --notransmit or --transmit false.

       -p, --packetsize Integer
              Specifies the padding size of transmitted ICMP datagram packets.
              The  default is 8, which translates into 16 ICMP data bytes when
              combined with the 8 bytes of the ICMP header data.

       -f, --file file
              Specifies the  path  and  filename  that  RSSI  values  will  be
              recorded to.

       -V, --version
              Prints the current version and copyright statement.

BUGS
       Known Bugs
              The  delimiter  field can not process escape characters and will
              cause the program to fail. The wireless device name is currently
              hardcoded to wlan0. To change this edit the rrs script file.

AUTHORS
       Ivan Boatwright & Julieth Diaz

COPYRIGHT
       Copyright (c) 2018 Ivan Boatwright

       rrs comes with NO WARRANTY, to the extent permitted by law.  For infor‐
       mation about the terms of redistribution, see the file named README  in
       the rrs distribution.

version 1.0.1                   7 December 2018                         rrs(1)